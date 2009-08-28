require 'spec'
require File.dirname(__FILE__)+"/../url"

describe "int2url" do
  it "converts from integer to url" do
    int2url(0).should == '0'
    int2url(9).should == '9'
    int2url(10).should == 'A'
    int2url(61).should == 'z'
    int2url(62).should == '10'
    int2url(125).should == '21'
  end
end

describe "url2int" do
  it "converts from url to integer" do
    url2int('0').should == 0
    url2int('9').should == 9
    url2int('A').should == 10
    url2int('z').should == 61
    url2int('10').should == 62
    url2int('21').should == 125
  end
end

describe "x2y" do
  it "is symmetrical" do
    (0..1_000_000).each do |i|
      url2int(int2url(i)).should == i
    end
  end
end
