platform :ios
  


target :matchers, :exclusive => true do
      pod 'OCHamcrest'
      link_with ['App Specs', 'Unit Specs']
end
 
target :spec, :exclusive => true do
      pod 'Kiwi',            :git => 'https://github.com/blazingcloud/Kiwi.git'
      link_with ['App Specs', 'Unit Specs']
  end

 target :integration do
     pod 'KIF'
     link_with 'Integration Tests'
 end