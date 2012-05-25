$original_sunspot_session = Sunspot.session
Sunspot.session = Sunspot::Rails::StubSessionProxy.new($original_sunspot_session)
