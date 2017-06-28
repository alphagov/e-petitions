Rails.application.routes.draw do
  constraints Site.constraints_for_public do
    get '/' => 'pages#index', :as => :home
    get 'help' => 'pages#help', :as => :help
    get 'privacy' => 'pages#privacy', :as => :privacy
    get 'browserconfig' => 'pages#browserconfig', format: true, constraints: { format: 'xml' }
    get 'manifest' => 'pages#manifest', format: true, constraints: { format: 'json' }

    get  'feedback', to: 'feedback#new', as: 'feedback'
    post 'feedback', to: 'feedback#create', as: nil
    get  'feedback/thanks', to: 'feedback#thanks', as: 'thanks_feedback'

    scope 'petitions' do
      get 'local' => 'local_petitions#index', as: 'local_petitions'
      get 'local/:id' => 'local_petitions#show', as: 'local_petition'
      get 'local/:id/all' => 'local_petitions#all', as: 'all_local_petition'
    end

    resources :petitions, :only => [:new, :show, :index] do
      collection do
        get 'check'
        get 'check_results'
      end

      member do
        get 'count', :action => :count, :as => :count
        get 'thank-you', :action => :thank_you, :as => :thank_you
        get 'gathering-support', :action => :gathering_support, :as => :gathering_support
        get 'moderation-info', :action => :moderation_info, :as => :moderation_info
      end

      resources :sponsors, only: [:show, :update], param: :token do
        get 'thank-you', on: :member
        get 'sponsored', on: :member
      end

      resources :signatures, :only => [:new] do
        post 'new' => 'signatures#create', :as => :sign, :on => :collection
        get 'thank-you', :action => :thank_you, :on => :collection, :as => :thank_you
      end
    end

    post 'petitions/new' => 'petitions#create', :as => :create_petition

    scope 'signatures/:id' do
      get 'verify(/:legacy_token)' => 'signatures#verify', :as => :verify_signature
      get 'unsubscribe(/:legacy_token)' => 'signatures#unsubscribe', :as => :unsubscribe_signature
      get 'signed(/:legacy_token)' => 'signatures#signed', :as => :signed_signature
    end

    namespace :archived do
      resources :petitions, only: [:index, :show]
    end

    # REDIRECTS OLD PAGES
    get '/departments',           to: redirect('/')
    get '/departments/:id',       to: redirect('/')
    get '/api/petitions',         to: redirect('/')
    get '/api/petitions/:id',     to: redirect('/')

    get '/privacy-policy',       to: redirect('/privacy')
    get '/accessibility',        to: redirect('/help')
    get '/terms-and-conditions', to: redirect('/help')
    get '/how-it-works',         to: redirect('/help')
    get '/faq',                  to: redirect('/help')

    get '/crown-copyright', to: redirect('https://www.nationalarchives.gov.uk/information-management/our-services/crown-copyright.htm')
  end

  constraints Site.constraints_for_moderation do
    get '/', to: redirect('/admin')

    namespace :admin do
      root :to => 'admin#index'

      mount Delayed::Web::Engine, at: '/delayed'

      resource :parliament, :only => [:show, :update]
      resource :search, :only => [:show]

      resources :admin_users
      resources :profile, :only => [:edit, :update]
      resources :user_sessions, :only => [:create]

      resources :invalidations, :except => [:show] do
        post :cancel, :count, :start, :on => :member
      end

      resources :petitions, :only => [:show, :index] do
        resource 'debate-outcome', only: [:show, :update], as: :debate_outcome, controller: :debate_outcomes
        resources :emails, only: [:new, :create, :edit, :update, :destroy], controller: :petition_emails
        resource :petition_details, :only => [:show, :update]
        resource :moderation, :only => [:update], controller: :moderation
        resource :notes, :only => [:show, :update]
        resource 'take-down', :only => [:show, :update], as: :take_down, controller: :take_down
        resource 'government-response', :only => [:show, :update], as: :government_response, controller: :government_response
        resource 'schedule-debate', :only => [:show, :update], as: :schedule_debate, controller: :schedule_debate
        resource 'tags', :only => [:show, :update]
      end

      resource :rate_limits, :only => [:edit, :update], :path => 'rate-limits'
      resource :settings, only: [:edit, :update], controller: "settings"

      resources :signatures, :only => [:index, :destroy] do
        post :validate, :invalidate, :on => :member
      end

      get 'logout' => 'user_sessions#destroy', :as => :logout
      get 'login' => 'user_sessions#new', :as => :login

      get 'continue' => 'user_sessions#continue', :as => :continue
      get 'status' => 'user_sessions#status', :as => :status
    end
  end

  get 'ping' => 'ping#ping'

  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)
end
