require 'date'

class TopChartsController< ApplicationController
  def index
  end

  def show
    # Params
    earliestDate = Date.parse(params[:startDate])
    latestDate = Date.parse(params[:endDate])
    rank = params[:minRank]
    aggregateSetting = params[:aggregateSetting]

    # Make DB query
    results = TopChart.select(:chart_week, :country, :artist, :rank).where(:chart_week => earliestDate..(latestDate)).where("rank <= "+rank.to_s)

    # Prepare combine results
    aggregatedResults = {
      "us" => {},
      "uk" => {},
      "artists" => []
    }

    # Create array of dates
    dateArray = createDateArray(earliestDate, latestDate, aggregateSetting)

    # Initialize data us/uk containers
    dateArray.each do |date|
      # Get correct key
      if aggregateSetting == "year"
        dateObj = Date.new(date.to_i, 1, 1)
      else
        dateObj = Date.new(date.split('/')[1].to_i, date.split('/')[0].to_i, 1)
      end

      # Add each date
      aggregatedResults['us'][date] = {"key": dateObj}
      aggregatedResults['uk'][date] = {"key": dateObj}
    end

    # Aggregate results
    results.each do |entry|
      # Create keys
      dateKey = createDateKey(entry.chart_week, aggregateSetting)
      country = entry['country']
      artist = entry['artist']

      # Put together a list of artists
      if (aggregatedResults['artists'].include? artist) == false
        aggregatedResults['artists'].append(artist)
      end

      # Add/increment artists' entry
      if aggregatedResults[country][dateKey].key?(artist) == false
        aggregatedResults[country][dateKey][artist] = 0
      end
      aggregatedResults[country][dateKey][artist] += 1
    end

    # Flatten
    aggregatedResults['us'] = flattenDict(aggregatedResults['us'])
    aggregatedResults['uk'] = flattenDict(aggregatedResults['uk'])

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
