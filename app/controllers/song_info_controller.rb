class SongInfoController < ApplicationController
  def index
    render text: 'heyo'
  end
  def show
    render text: params['value']
  end
end
