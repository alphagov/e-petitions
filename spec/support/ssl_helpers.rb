def with_ssl(&block)
  context "over an secure http connection" do
    before :each do
      @request.env['HTTPS'] = 'on'
    end
    self.instance_eval(&block)
    after :each do
      @request.env['HTTPS'] = nil
    end
  end
end

def without_ssl(&block)
  context "over a normal http connection" do
    before :each do
      @request.env['HTTPS'] = nil
    end
    self.instance_eval(&block)
    after :each do
      @request.env['HTTPS'] = nil
    end
  end
end