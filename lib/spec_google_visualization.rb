require 'active_support'
require 'spec'
require 'google_visualization.rb'

class CollectionFixture
  attr_accessor :label, :time, :x, :y, :bubble_size, :extra, :extra_2

  def initialize(attributes)
    attributes.each {|key,value| self.send((key.to_s + "=").to_sym, value)}
  end
end

describe GoogleVisualization do
  describe GoogleVisualization::GapMinder do
    before do
      @collection = [CollectionFixture.new(:label => "Monkey", :time => Date.today, :x => 5, :y => 10, :bubble_size => 50, :extra => 1, :extra_2 => 2)]

      @gap_minder = GoogleVisualization::GapMinder.new(self, @collection)
      @gap_minder.label("Department") {|cf| cf.label}
      @gap_minder.time("Time of Year") {|cf| cf.time}
      @gap_minder.x("X Axis") {|cf| cf.x}
      @gap_minder.y("Y Axis") {|cf| cf.y}
      @gap_minder.bubble_size("Bubble Size") {|cf| cf.bubble_size}
      @gap_minder.extra_column("Extra") {|cf| cf.extra }
      @gap_minder.extra_column("Extra 2") {|cf| cf.extra_2 }

      @invalid_gap_minder = GoogleVisualization::GapMinder.new(self, @collection)
    end

    it "should build a valid procedure_hash" do
      @gap_minder.procedure_hash.should be_instance_of(Hash)
      @gap_minder.procedure_hash.should_not be_empty
      @gap_minder.procedure_hash.each do |key,value|
        @gap_minder.procedure_hash[key].should be_instance_of(Array)
        #key.should be_instance_of(Symbol)
	value[0].should be_instance_of(String)
	value[1].should be_instance_of(Proc)
      end
    end

    it "should render valid columns" do
      puts "\n"
      puts @gap_minder.render_columns
    end

    it "should render valid rows" do
      puts "\n"
      puts @gap_minder.render_rows
    end

    it "should raise and exception" do
      lambda {@invalid_gap_minder.render_columns}.should raise_error
    end

  end

  describe GoogleVisualization::Mappings do
    it "#ruby_to_google_type should produce the correct types" do
      GoogleVisualization::Mappings.ruby_to_google_type(String).should == "string" 
      GoogleVisualization::Mappings.ruby_to_google_type(Date).should == "date" 
      GoogleVisualization::Mappings.ruby_to_google_type(Fixnum).should == "number" 
      GoogleVisualization::Mappings.ruby_to_google_type(Float).should == "number" 
      GoogleVisualization::Mappings.ruby_to_google_type(Time).should == "datetime" 
    end

    it "#ruby_to_javascript_object should produce the correct javascript" do
      GoogleVisualization::Mappings.ruby_to_javascript_object(Date.parse("2008-01-02")).should == "new Date(2008,01,02)" 
      GoogleVisualization::Mappings.ruby_to_javascript_object("my string").should == "'my string'" 
      GoogleVisualization::Mappings.ruby_to_javascript_object(8).should == 8
      GoogleVisualization::Mappings.ruby_to_javascript_object(8.6).should == 8.6
    end

    it "#columns should be a list of symbols" do
      GoogleVisualization::Mappings.columns.should be_instance_of Array
    end
  end
end
