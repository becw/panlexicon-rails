require 'spec_helper'

describe MobyImporter do
  let(:txt) { Pathname('spec/fixtures/not_moby.txt') }
  let(:moby_importer) { MobyImporter.new(txt) }

  it "has a valid fixture" do
    expect(txt.exist?).to be_true
  end

  it "imports terms" do
    expect{moby_importer.import}.to change{Term.count}.from(0).to(7)
  end

  it "is idempotent" do
    moby_importer.import

    expect{moby_importer.import}.to_not change{Term.count}
  end

end