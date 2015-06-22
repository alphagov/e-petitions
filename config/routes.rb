Rails.application.routes.draw do
  get '/' => 'static_pages#home', :as => :home
  get 'help' => 'static_pages#help', :as => 'help'
  get 'ping' => 'ping#ping'

  get 'feedback' => 'feedback#index', :as => 'feedback'
  get 'feedback/thanks' => 'feedback#thanks', :as => 'thanks_feedback'
  post 'feedback' => 'feedback#create', :as => nil

  resources :petitions, :only => [:new, :show, :index] do
    collection do
      get 'check'
      get 'check_results'
      get 'local' => 'local_petitions#index'
    end

    member do
      post 'resend_confirmation_email'
      get  'thank-you', :action => :thank_you, :as => :thank_you
      get  'moderation-info', :action => :moderation_info, :as => :moderation_info
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
    resources :petitions, :only => [:show, :index] do
      collection do
        get :threshold
      end
      member do
        get   :edit_response
        patch :update_response
        get   :edit_scheduled_debate_date
        patch :update_scheduled_debate_date
        patch :take_down
      end
      resource 'debate-outcome', only: [:show, :update], as: :debate_outcome, controller: :debate_outcomes
      resource :petition_details, :only => [:show, :update]
      resource :moderation, :only => [:update], controller: :moderation
      resource :notes, :only => [:show, :update]
      resource 'take-down', :only => [:show, :update], as: :take_down, controller: :take_down
    end
    resources :profile, :only => [:edit, :update]
    resources :user_sessions, :only => [:create]
    get 'logout' => 'user_sessions#destroy', :as => :logout
    get 'login' => 'user_sessions#new', :as => :login
  end
end
