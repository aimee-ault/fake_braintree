require "spec_helper"

describe "Braintree::ClientToken.generate" do
  it "works" do
    expect(SecureRandom).to receive(:hex).and_return("abcdef")
    token = Braintree::ClientToken.generate
    expect(token).to eq "abcdef"
  end
end