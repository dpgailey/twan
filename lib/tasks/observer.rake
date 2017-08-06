namespace :observer do
  desc "Get the list of followers, add new ones, refresh old ones."
  task update: :environment do
    account_type = "Twitter"
    account = Account.first
    account.followers_count = account.followers_count
    account.friends_count = account.friends_count
    user = User.find(1)
    followers = account.get_followers

    # Friends are people you are following,
    # Why they name it friends, I have no idea.

    friends = account.get_friends
  end
end
