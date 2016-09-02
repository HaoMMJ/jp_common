Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get 'index'   => 'collect#index'
  get 'collect_all'   => 'collect#collect_all'
  get 'save'    => 'collect#save'
  get 'fix_302' => 'collect#fix_302'
end
