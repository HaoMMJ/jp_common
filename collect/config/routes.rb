Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get 'index'   => 'collect#index'
  get 'collect_all'   => 'collect#collect_all'
  get 'jlpt_collect'   => 'collect#jlpt_collect'
  get 'jlpt_insert'   => 'collect#jlpt_insert'
  get 'save'    => 'collect#save'
  get 'fix_302' => 'collect#fix_302'
  get 'filter'  => 'collect#filter'
  get 'fix_unicode_insert' => 'collect#fix_unicode_insert'
  get 'insert_wrong_format' => 'collect#insert_wrong_format'

  get 'common_list' => 'show#common_list'
  get 'create_meaning' => 'show#create_meaning'
  get 'filter_15000' => 'show#filter_15000'
  get 'create_jisho_meaning' => 'show#create_jisho_meaning'
end
