Rails.application.routes.draw do
  get '/' => 'static_pages#home', :as => :home
  get 'how-it-works' => 'static_pages#how_it_works', :as => 'how_it_works'
  get 'help' => 'static_pages#help', :as => 'help'

  get 'feedback' => 'feedback#index', :as => 'feedback'
  get 'feedback/thanks' => 'feedback#thanks', :as => 'thanks_feedback'
  post 'feedback' => 'feedback#create', :as => nil

  resources :petitions, :only => [:new, :show, :index] do
    collection do
      get 'check'
      get 'check_results'
    end

    member do
      post 'resend_confirmation_email'
      get  'thank-you', :action => :thank_you, :as => :thank_you
    end
    resources :sponsors, only: [:show, :update], param: :token do
      get 'thank-you', on: :member
      get 'sponsored', on: :member
    end

    resources :signatures, :only => [:new] do
      post 'new' => 'signatures#create', :as => :sign, :on => :collection
      get 'thank-you', :action => :thank_you, :on => :collection, :as => :thank_you
      get 'signed', :action => :signed, :on => :member, :as => :signed
    end
  end

  post 'petitions/new' => 'petitions#create', :as => :create_petition

  get 'search' => 'search#search', :as => :search

  resources :signatures, :only => [] do
    get 'verify/:token', :action => :verify, :on => :member, :as => :verify
    get 'unsubscribe/:unsubscribe_token', :action => :unsubscribe, :on => :member, :as => :unsubscribe
  end

  namespace :archived do
    resources :petitions, only: [:index, :show] do
      get :search, on: :collection
    end
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
        get   :edit_response
        patch :update_response
        patch :take_down
      end
    end
    resources :profile, :only => [:edit, :update]
    resources :reports,  :only => [:index]
    resources :user_sessions, :only => [:create]
    get 'logout' => 'user_sessions#destroy', :as => :logout
    get 'login' => 'user_sessions#new', :as => :login
  end

  namespace :api do
    resources :petitions, :only => [:index, :show]
  end
end
