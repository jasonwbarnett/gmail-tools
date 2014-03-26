require 'sinatra'
require 'sinatra/cookies'
require 'logger'
require './gmail_lib.rb'

$LOG = Logger.new('application.log', 30, 'daily') 

set :show_exceptions, false

set(:cookie_options) do
  { :expires => Time.now + 60 * 15 }
end

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
  username  = params[:gmail]["username"]
  password  = params[:gmail]["password"]

  dry_run   = true
  dry_run   = false if params[:gmail]["dry_run"] == "false"

  rename    = "false"
  rename    = "true"  if params[:gmail]["rename"]  == "true"

  rename_from = params[:gmail]["rename_from"] ? params[:gmail]["rename_from"] : nil
  rename_to   = params[:gmail]["rename_to"]   ? params[:gmail]["rename_to"]   : nil

  ## Set cookies
  cookies[:username]    = username
  cookies[:rename]      = rename
  cookies[:rename_from] = rename_from #unless rename_from.nil?
  cookies[:rename_to]   = rename_to   #unless rename_to.nil?

  $LOG.info "#{username},#{password},#{dry_run.inspect}"

  begin
    @gmail = GmailTools.new(username, password, dry_run: dry_run)
    @gmail.create_missing_labels
    @gmail.rename_labels_root(rename_from, rename_to) if rename == "true" and (!rename_from.nil? or !rename_to.nil?)
  rescue Net::IMAP::NoResponseError => e
    @error = e.message
    $LOG.error e.message
  end
  $LOG.info @gmail.inspect


  erb :"labels/fix_missing"
end
