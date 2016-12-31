Rails.application.routes.draw do
  scope '/api' do
    scope '/charts' do
      get '/' => 'top_charts#index'
      scope ':country' do
        get '/' => 'top_charts#show', :artist => "all"
        scope ':artist' do
          get '/' => 'top_charts#show'
        end
      end
    end
    scope '/test' do
      get '/' => 'song_info#index'
      scope ':value' do
        get '/' => 'song_info#show'
      end
    end
    scope '/artist' do
      get '/' => 'artist_info#index'
      scope ':artist' do
        get '/' => 'artist_info#show', :constraints => {:artist => /[^\/]+/ }
      end
    end
  end
end
