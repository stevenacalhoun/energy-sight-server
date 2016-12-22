require 'date'

class Hot100EntryController < ApplicationController
  def index
    # Params
    earliestDate = Date.parse(params[:startDate])
    latestDate = Date.parse(params[:endDate])
    rank = params[:minRank]

    results = Hot100Entry.select('"chartWeek", artist, rank').where(:chartWeek =>  earliestDate..(latestDate+7)).where(:country => country)
    .where("rank <= "+rank.to_s)

    render json: results
  end

  def show
    # Params
    earliestDate = Date.parse(params[:startDate])
    latestDate = Date.parse(params[:endDate])
    rank = params[:minRank]
    aggregateSetting = params[:aggregateSetting]

    # Make DB query
    results = TopChart.select('top_charts.chart_week, top_charts.country, songs.artist, songs.title, top_charts.rank').joins(:song).where('top_charts.chart_week' => earliestDate..(latestDate)).where("top_charts.rank <= "+rank.to_s)

    # Data containers
    artists = []
    usDataDict = {}
    ukDataDict = {}

    # Create array of dates
    dateArray = createDateArray(earliestDate, latestDate, aggregateSetting)

    # Put together list of artists
    results.each do |entry|
      if (artists.include? entry['artist']) == false
        artists.append(entry['artist'])
      end
    end

    # Initialize data us/uk containers
    dateArray.each do |date|
      if aggregateSetting == "year"
        dateObj = Date.new(date[0].to_i, 1, 1)
      else
        dateObj = Date.new(date.split('/')[1].to_i, date.split('/')[0].to_i, 1)
      end

      usDataDict[date] = {"key": dateObj}
      ukDataDict[date] = {"key": dateObj}

      artists.each do |artist|
        usDataDict[date][artist] = 0
        ukDataDict[date][artist] = 0
      end
    end

    # Aggregate results
    results.each do |entry|
      dateKey = createDateKey(entry.chart_week, aggregateSetting)
      if entry['country'] == 'us'
        usDataDict[dateKey][entry['artist']] = usDataDict[dateKey][entry['artist']] + 1
      else
        ukDataDict[dateKey][entry['artist']] = ukDataDict[dateKey][entry['artist']] + 1
      end
    end

    # Prepare combine results
    aggregatedResults = {
      "us": flattenDict(usDataDict),
      "uk": flattenDict(ukDataDict),
      "artists": artists
    }

    render json: aggregatedResults
  end
end

def createDateArray(startDate, endDate, mode)
  if mode == "year"
    dateArray = ((startDate)..endDate).map{|d| d.year.to_s}.uniq
  else
    dateArray = ((startDate)..endDate).map{|d| d.month.to_s + "/" + d.year.to_s}.uniq
  end

  return dateArray
end

def createDateKey(date, mode)
  if mode == "year"
    key = date.year.to_s
  else
    key = date.month.to_s + "/" + date.year.to_s
  end
  return key
end

def flattenDict(dict)
  array = []
  dict.each do |key, data|
    array.append(data)
  end
  return array
end
