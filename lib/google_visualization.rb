# GoogleVisualization
module GoogleVisualization
  class GapMinder

    attr_reader :collection, :collection_methods, :options, :size, :helpers, :procedure_hash, :name

    def method_missing(method, *args, &block)
      if Mappings.columns.include?(method)
        procedure_hash[method] = [args[0], block]
      else
        helpers.send(method, *args, &block)
      end
    end
    
    def initialize(view_instance, collection, options={}, *args)
      @helpers = view_instance
      @collection = collection
      @collection_methods = collection_methods
      @options = options.reverse_merge({:width => 600, :height => 300})
      @columns = []
      @rows = []
      @procedure_hash = {:color => ["Department", lambda {|item| label_to_color(@procedure_hash[:label][1].call(item)) }] }
      @size = collection.size
      @name = "gap_minder_#{self.id.to_s.gsub("-","")}"
      @labels = {}
      @color_count = 0
    end

    def header
      content_tag(:div, "", :id => name, :style => "width: #{options[:width]}px; height: #{options[:height]}px;")
    end

    def body
      javascript_tag do
        "var data = new google.visualization.DataTable();\n" +
        "data.addRows(#{size});\n" +
        render_columns +
	render_rows +
        "var #{name} = new google.visualization.MotionChart(document.getElementById('#{name}'));\n" +
        "#{name}.draw(data, {width: #{options[:width]}, height: #{options[:height]}});"
      end
    end

    def render
      header + "\n" + body
    end

    def render_columns
      if required_methods_supplied?
        Mappings.columns.each { |c| @columns << gap_minder_add_column(procedure_hash[c]) }
        procedure_hash.each { |key, value| @columns << gap_minder_add_column(value) if not Mappings.columns.include?(key) }
        @columns.join("\n")
      end
    end

    def render_rows
      if required_methods_supplied?
        collection.each_with_index do |item, index|
          Mappings.columns.each_with_index {|name,column_index| @rows << gap_minder_set_value(index, column_index, procedure_hash[name][1].call(item)) }
          procedure_hash.each {|key,value| @rows << gap_minder_set_value(index, key, procedure_hash[key][1].call(item)) unless Mappings.columns.include?(key) }
        end
        @rows.join("\n")
      end
    end

    def required_methods_supplied?
      Mappings.columns.each do |key|
        unless procedure_hash.has_key? key
          raise "GapMinder Must have the #{key} method called before it can be rendered"
	end
      end
    end

    def gap_minder_add_column(title_proc_tuple)
      title = title_proc_tuple[0]
      procedure = title_proc_tuple[1]
      "data.addColumn('#{google_type(procedure)}','#{title}');\n"
    end
  
    def gap_minder_set_value(row, column, value)
      "data.setValue(#{row}, #{column}, #{Mappings.ruby_to_javascript_object(value)});\n"
    end
  
    def google_type(procedure)
      Mappings.ruby_to_google_type(procedure.call(collection[0]).class)
    end

    def google_formatted_value(value)
      Mappings.ruby_to_javascript_object(value)
    end
  
    def label_to_color(label)
      hashed_label = label.downcase.gsub(" |-","_").to_sym
      if @labels.has_key? hashed_label
        @labels[hashed_label]
      else
        @color_count += 1
	@labels[hashed_label] = @color_count
      end
    end

    def extra_column(title, &block)
      procedure_hash[procedure_hash.size] = [title, block]
    end

  end

  module Mappings
    def self.ruby_to_google_type(type)
      type_hash = {
        :String => "string",
        :Fixnum => "number",
        :Float => "number",
        :Date => "date",
        :Time => "datetime"
      }
      type_hash[type.to_s.to_sym]
    end

    def self.ruby_to_javascript_object(value)
      value_hash = {
        :String => lambda {|v| "'#{v}'"},
        :Date => lambda {|v| "new Date(#{v.to_s.gsub("-",",")})"},
        :Fixnum => lambda {|v| v },
	:Float => lambda {|v| v }
      }
      value_hash[value.class.to_s.to_sym].call(value)
    end

    def self.columns
      [:label, :time, :x, :y, :color, :bubble_size]
    end
  end

  module Helpers
    def gap_minder_for(collection, options={}, *args, &block)
      gap_minder = GapMinder.new(self, collection, options)
      yield gap_minder
      concat(gap_minder.render, block.binding)
    end
  end
end
