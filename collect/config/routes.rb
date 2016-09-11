Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  #10000 common
  get 'index'   => 'collect#index'
  get 'collect_all'   => 'collect#collect_all'
  get 'jlpt_collect'   => 'collect#jlpt_collect'
  get 'jlpt_insert'   => 'collect#jlpt_insert'
  get 'save'    => 'collect#save'
  get 'fix_302' => 'collect#fix_302'
  get 'filter'  => 'collect#filter'
  get 'fix_unicode_insert' => 'collect#fix_unicode_insert'
  get 'insert_wrong_format' => 'collect#insert_wrong_format'
  get 'common_list' => 'collect#common_list'
  get 'create_meaning' => 'collect#create_meaning'
  get 'create_missing_words' => 'collect#create_missing_words'
  get 'filter_15000' => 'collect#filter_15000'
  get 'create_jisho_meaning' => 'collect#create_jisho_meaning'
  get 'create_missing_meanings' => 'collect#create_missing_meanings'
  get 'fix_not_found' => 'collect#fix_not_found'

  #Minna
  get 'create_minna_raw_data' => 'minna#create_minna_raw_data'
  get 'create_minna_dictionary' => 'minna#create_minna_dictionary'
  get 'create_minna_quizlet' => 'minna#create_minna_quizlet'

end
