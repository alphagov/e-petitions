Epets::Application.routes.draw do
  match '/' => 'static_pages#home', :as => :home
  match 'accessibility' => 'static_pages#accessibility', :as => 'accessibility'
  match 'how-it-works' => 'static_pages#how_it_works', :as => 'how_it_works'
  match 'terms-and-conditions' => 'static_pages#terms_and_conditions', :as => 'terms_and_conditions'
  match 'privacy-policy' => 'static_pages#privacy_policy', :as => 'privacy_policy'
  match 'crown-copyright' => 'static_pages#crown_copyright', :as => 'crown_copyright'
  match 'faq' => 'static_pages#faq', :as => 'faq'

  get 'feedback' => 'feedback#index', :as => 'feedback'
  get 'feedback/thanks' => 'feedback#thanks', :as => 'thanks_feedback'
  post 'feedback' => 'feedback#create', :as => 'feedback'

  resources :departments, :only => [:index, :show] do
    get 'info', :action => :info, :on => :collection, :as => :info
  end

  resources :petitions, :only => [:new, :show, :index] do
    collection do
      get 'check'
      get 'check_results'
    end

    member do
      post 'resend_confirmation_email'
      get  'thank-you', :action => :thank_you, :as => :thank_you
    end

    resource :signature, :only => [:new] do
      post 'new' => 'signatures#create', :as => :sign
      get 'thank-you', :action => :thank_you, :on => :collection, :as => :thank_you
      get 'signed', :action => :signed, :on => :collection, :as => :signed
    end
  end

  post 'petitions/new' => 'petitions#create', :as => :create_petition

  get 'search' => 'search#search', :as => :search

  resources :signatures, :only => [] do
    get 'verify/:token', :action => :verify, :on => :member, :as => :verify
  end

  namespace :admin do
    root :to => 'todolist#index'

    resource :search, :only => [:new] do
      get :result, :on => :member
      get :petition_by_id, :on => :member
    end

    resources :admin_users
    resources :petitions, :only => [:show, :edit, :update, :index] do
      collection do
        get :threshold
      end
      member do
        get :edit_response
        put :update_response
        get :edit_internal_response
        put :update_internal_response
        put :take_down
      end
    end
    resources :profile, :only => [:edit, :update]
    resources :reports,  :only => [:index]
    resources :user_sessions, :only => [:create]
    match 'logout' => 'user_sessions#destroy', :as => :logout
    match 'login' => 'user_sessions#new', :as => :login
  end

  namespace :api do
    resources :petitions, :only => [:index, :show]
  end
end
