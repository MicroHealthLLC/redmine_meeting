# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects do
  resources :meetings do
    get 'calendar', on: :collection
    get 'schedule', on: :collection
    get 'participate', on: :member
    get 'not_participating', on: :member
  end
end

get 'meetings/:id', controller: 'meetings', :action=> 'show'