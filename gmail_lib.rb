require 'io/console'
require 'gmail'

class GmailTools
  attr_accessor :renamed_inbox, :dry_run, :renamed_labels, :created_labels, :username

  def initialize(username, password, options={})
    self.renamed_inbox  = options[renamed_inbox] ? options[renamed_inbox] : "MJ-Inbox"
    self.dry_run        = options[dry_run]       ? options[dry_run]       : true
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
        begin
          @gmail.create_label k unless self.dry_run == true
        rescue Net::IMAP::NoResponseError => e
          if e.message =~ /Duplicate folder name/
            self.created_labels << {label: k, message: "skipped, label already exists"}
            puts "skipped, label already exists"
          else
            self.created_labels << {label: k, message: "ERROR: #{e.message}"}
            $stderr.puts "ERROR: #{e.message}"
          end
        else
          self.created_labels << {label: k, message: "Created!"}
          puts "Created!"
        end
      end
    end
  end

  ## Rename all Inbox/ labels to #{self.renamed_inbox}/
  def rename_inbox_to_mj_inbox
    gmail_labels = @gmail.labels
    gmail_labels.sort! do |x,y|
      r = y.split('/').length <=> x.split('/').length
      r = x.downcase <=> y.downcase if r == 0
      r
    end

    gmail_labels.each do |label|
      if label =~ %r{^Inbox/}
        updated_label = label.sub("Inbox/","#{self.renamed_inbox}/")
      else
        next
      end

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
  end
end
