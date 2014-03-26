require 'sinatra'
require 'logger'
require './gmail_lib.rb'

$LOG = Logger.new('application.log', 30, 'daily') 

set :show_exceptions, true

helpers do
  # If @title is assigned, add it to the page's title.
  def title
    if @title
      "#{@title} :: Gmail Tools"
    else
      "Gmail Tools"
    end
  end

  # Format the Ruby Time object returned from a post's created_at method
  # into a string that looks like this: 06 Jan 2012
  def pretty_date(time)
   time.strftime("%d %b %Y")
  end

end

get '/' do
  erb :index
end

get %r{/labels/?} do
  erb :"labels/index"
end

post '/labels/fix_missing' do
  $LOG.info "PARAMS: #{params[:gmail].inspect}"
  username = params[:gmail]["username"]
  password = params[:gmail]["password"]
  dry_run  = params[:gmail]["dry_run"]  ? params[:gmail]["dry_run"] : true
  dry_run  = false if dry_run == "false"

  $LOG.info "#{username},#{password},#{dry_run}"

  @gmail = GmailTools.new(username, password, dry_run: dry_run)
  $LOG.info @gmail.inspect

  @gmail.create_missing_labels

  erb :"labels/fix_missing"
end
