class Account < ApplicationRecord
  belongs_to :user

  # twitter hash results here: https://gist.github.com/dpgailey/8a598798a937c3f410f52c15d33ff0a2
  def get_followers
    client = get_client
    all_friends = get_twitter_followers_with_cursor(self.cursor,[],client)
  end

  def get_following
    client = get_client
    all_friends = get_twitter_friends_with_cursor(self.cursor,[],client)
  end

  def get_client
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_KEY']
      config.consumer_secret     = ENV['TWITTER_SECRET']
      config.access_token        = ENV['TWITTER_USER_KEY']
      config.access_token_secret = ENV['TWITTER_USER_SECRET']
    end
  end


  # params: relationship_type : {Follower, Friend}

  '''
  {:id=>24925304, :id_str=>"24925304", :name=>"Russ Smith", :screen_name=>"russ_sm", :location=>"", :description=>"Just smart enough to be dangerous.  CPO at @codeqco. Beef stroganoff enthusiast. Cyberpunk af.", :url=>"http://t.co/fkDVouoFRA", :entities=>{:url=>{:urls=>[{:url=>"http://t.co/fkDVouoFRA", :expanded_url=>"http://www.codeq.com/", :display_url=>"codeq.com", :indices=>[0, 22]}]}, :description=>{:urls=>[]}}, :protected=>false, :followers_count=>322, :friends_count=>523, :listed_count=>9, :created_at=>"Tue Mar 17 18:18:40 +0000 2009", :favourites_count=>273, :utc_offset=>-25200, :time_zone=>"Pacific Time (US & Canada)", :geo_enabled=>true, :verified=>false, :statuses_count=>3206, :lang=>"en", :status=>{:created_at=>"Sat Aug 05 17:34:11 +0000 2017", :id=>893887872285130753, :id_str=>"893887872285130753", :text=>"@noopkat https://t.co/zIO8CndUxF", :truncated=>false, :entities=>{:hashtags=>[], :symbols=>[], :user_mentions=>[{:screen_name=>"noopkat", :name=>"Suz Hinton 🐢 a memé", :id=>8942382, :id_str=>"8942382", :indices=>[0, 8]}], :urls=>[{:url=>"https://t.co/zIO8CndUxF", :expanded_url=>"http://www.myrapname.com/", :display_url=>"myrapname.com", :indices=>[9, 32]}]}, :source=>"<a href=\"http://twitter.com\" rel=\"nofollow\">Twitter Web Client</a>", :in_reply_to_status_id=>893851389700571136, :in_reply_to_status_id_str=>"893851389700571136", :in_reply_to_user_id=>8942382, :in_reply_to_user_id_str=>"8942382", :in_reply_to_screen_name=>"noopkat", :geo=>nil, :coordinates=>nil, :place=>nil, :contributors=>nil, :is_quote_status=>false, :retweet_count=>0, :favorite_count=>0, :favorited=>false, :retweeted=>false, :possibly_sensitive=>false, :lang=>"und"}, :contributors_enabled=>false, :is_translator=>false, :is_translation_enabled=>false, :profile_background_color=>"FFFFFF", :profile_background_image_url=>"http://pbs.twimg.com/profile_background_images/152068902/backround2.png", :profile_background_image_url_https=>"https://pbs.twimg.com/profile_background_images/152068902/backround2.png", :profile_background_tile=>false, :profile_image_url=>"http://pbs.twimg.com/profile_images/621057783736053760/0q2nh2k1_normal.jpg", :profile_image_url_https=>"https://pbs.twimg.com/profile_images/621057783736053760/0q2nh2k1_normal.jpg", :profile_banner_url=>"https://pbs.twimg.com/profile_banners/24925304/1421256503", :profile_link_color=>"91D2FA", :profile_sidebar_border_color=>"000000", :profile_sidebar_fill_color=>"FFFFFF", :profile_text_color=>"000000", :profile_use_background_image=>false, :has_extended_profile=>false, :default_profile=>false, :default_profile_image=>false, :following=>false, :live_following=>false, :follow_request_sent=>false, :notifications=>false, :muting=>false, :blocking=>false, :blocked_by=>false, :translator_type=>"none"}
  '''
  def add_relationship(follower, relationship_type, account_type="Twitter")
    account = Account.find_by(account_type: account_type, name: follower[:screen_name])
    if account.blank?
      account = Account.create(
                     account_type: account_type,
                     display_name: follower[:name],
                     name: follower[:screen_name],
                     followers_count: follower[:followers_count],
                     friends_count: follower[:friends_count]
                     )
      puts "Adding: "   + account.display_name + "(" + account.name + ") Followers: " + account.followers_count.to_s + ", Friends: " + follower[:friends_count].to_s
    else
      Account.update(followers_count: follower[:followers_count],
                     friends_count: follower[:friends_count]
                     )
      puts "Updating: " + account.display_name + "(" + account.name + ") Followers: " + account.followers_count.to_s + ", Friends: " + follower[:friends_count].to_s
    end

    Relationship.find_or_create_by(user_id: self.user.id,
                        account_id: account.id,
                        relationship_type: relationship_type)
    puts account.id
  end


  def get_twitter_friends_with_cursor(cursor, list, client)
    self.cursor = cursor
    self.save
    if cursor == 0
      return true
    else
      begin
        hashie = client.friends(:cursor => cursor)
        puts "Friends request made"
        h = hashie.to_h
        # records are in chronological order I think
        h[:users].each {|u| add_relationship(u, "Friend") }                              # Concat users to list

        get_twitter_friends_with_cursor(h[:next_cursor],list,client) # Recursive step using the next cursor
      rescue Twitter::Error::TooManyRequests
        self.save
        delay_until = Time.now + 16.minutes
        while Time.now < delay_until
          puts "Too many requests reached. Sleeping. " + delay_until.to_s
          sleep(5)
        end
        get_twitter_friends_with_cursor(cursor,list,client) # Recursive step using the next cursor
      rescue Twitter::Error::ServiceUnavailable
        delay_until = Time.now + 3.minutes
        while Time.now < delay_until
          puts "Sleeping(30): Service Unavailable. Time: " + Time.now.to_s + ", Until: "+ delay_until.to_s
          sleep(30)
        end
        get_twitter_friends_with_cursor(cursor,list,client) # Recursive step using the next cursor
      end
    end
  end

  def get_twitter_followers_with_cursor(cursor, list, client)
    self.cursor = cursor
    self.save

    if cursor == 0
      return true
    else
      begin
        hashie = client.followers(:cursor => cursor)
        puts "Follower request made"
        h = hashie.to_h
        h[:users].each {|u| add_relationship(u, "Follower") }                              # Concat users to list
        get_twitter_followers_with_cursor(h[:next_cursor],list,client) # Recursive step using the next cursor
      rescue Twitter::Error::TooManyRequests
        delay_until = Time.now + 16.minutes
        while Time.now < delay_until
          puts "Sleeping(30): Too many requests reached. Time: " + Time.now.to_s + ", Until: "+ delay_until.to_s
          sleep(30)
        end
        get_twitter_followers_with_cursor(cursor,list,client) # Recursive step using the next cursor
      rescue Twitter::Error::ServiceUnavailable
        delay_until = Time.now + 3.minutes
        while Time.now < delay_until
          puts "Sleeping(30): Service Unavailable. Time: " + Time.now.to_s + ", Until: "+ delay_until.to_s
          sleep(30)
        end
        get_twitter_followers_with_cursor(cursor,list,client) # Recursive step using the next cursor
      end
    end
  end

end
