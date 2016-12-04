Rails.application.routes.draw do
  scope '/api' do
    scope '/charts' do
      get '/' => 'hot_100_entry#index'
      scope ':country' do
        get '/' => 'hot_100_entry#show', :artist => "all"
        scope ':artist' do
          get '/' => 'hot_100_entry#show'
        end
      end
    end
    scope '/song' do
      get '/' => 'song_info#index'
    end
    scope '/artist' do
      get '/' => 'artist_info#index'
      scope ':artist' do
        get '/' => 'artist_info#show'
      end
    end
  end
end
