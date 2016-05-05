# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects do
  resources :meetings do
    get 'calendar', on: :collection
  end
end

get 'meetings/:id', controller: 'meetings', :action=> 'show'