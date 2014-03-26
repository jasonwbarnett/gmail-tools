require 'io/console'
require 'gmail'

class GmailTools
  attr_accessor :renamed_inbox, :dry_run, :renamed_labels, :created_labels, :username

  def initialize(username, password, options={})
    self.renamed_inbox  = options[:renamed_inbox] ? options[:renamed_inbox] : "MJ-Inbox"
    if options[:dry_run] == false
      self.dry_run = false
    else
      self.dry_run = true
    end
    self.username       = username
    self.renamed_labels = []
    self.created_labels = []

    @gmail = Gmail.new(username, password) 
  end

  def create_missing_labels
    label_counts = Hash.new(0)
    @gmail.labels.each do |label|
      hierarchy = label.scan(%r{[^/]+})
      hierarchy.pop

      label_counts[hierarchy.join('/')] += 1
    end

    gmail_labels = @gmail.labels
    label_counts.each do |k,v|
      next if k.nil? or k.empty? or k == "Inbox"
      if v > 1 and !gmail_labels.include?(k)
        create_label(k)
      end
    end
  end


  ## Rename all labels prefixed with #{rename_from}/... to #{rename_to}/...
  def rename_labels_root(rename_from, rename_to)
    gmail_labels = @gmail.labels
    gmail_labels.sort! do |x,y|
      r = y.split('/').length <=> x.split('/').length
      r = x.downcase <=> y.downcase if r == 0
      r
    end

    gmail_labels.each do |label|
      next unless label =~ %r{^#{rename_from}/}
      updated_label = label.sub(%r{^#{rename_from}/}, "#{rename_to}/")

      begin
        print "Renaming \"#{label}\" to \"#{updated_label}\"... "
        @gmail.rename_label(label, updated_label) unless self.dry_run == true
      rescue Net::IMAP::NoResponseError => e
        self.renamed_labels << {old_label: label, new_label: updated_label, message: "ERROR: #{e.message}"}
        $stderr.puts "ERROR: #{e.message}"
      else
        self.renamed_labels << {old_label: label, new_label: updated_label, message: "Renamed"}
        puts "Success!"
      end
    end
    create_label(rename_to) if self.renamed_labels.count > 0
  end


  private
    def create_label(label)
        begin
          @gmail.create_label label unless self.dry_run == true
        rescue Net::IMAP::NoResponseError => e
          if e.message =~ /Duplicate folder name/
            self.created_labels << {label: label, message: "skipped, label already exists"}
            puts "skipped, label already exists"
          else
            self.created_labels << {label: label, message: "ERROR: #{e.message}"}
            $stderr.puts "ERROR: #{e.message}"
          end
        else
          self.created_labels << {label: label, message: "Created!"}
          puts "Created!"
        end
    end
end
