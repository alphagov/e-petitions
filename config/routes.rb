Rails.application.routes.draw do
  constraints Site.constraints_for_public do
    controller 'constituencies' do
      get '/constituencies', action: 'index', as: :constituencies

      constraints period: /\d{4}-\d{4}|current/ do
        get '/parliaments/:period/constituencies', action: 'index', as: nil
      end
    end

    controller 'parliaments' do
      get '/parliaments', action: 'index', as: :parliaments
      get '/parliaments/:period', action: 'show', constraints: { period: /\d{4}-\d{4}/ }
    end

    controller 'topics' do
      get '/topics', action: 'index', as: :topics
    end

    controller 'pages' do
      get '/', action: 'index', as: :home

      scope action: 'show' do
        get '/accessibility', defaults: { slug: 'accessibility' }
        get '/cookies',       defaults: { slug: 'cookies' }
        get '/help',          defaults: { slug: 'help' }
        get '/privacy',       defaults: { slug: 'privacy' }
      end

      scope format: true do
        constraints format: 'xml' do
          defaults format: 'xml' do
            get '/browserconfig', action: 'browserconfig'
          end
        end

        constraints format: 'json' do
          defaults format: 'json' do
            get '/manifest', action: 'manifest'
            get '/trending', action: 'trending'
          end
        end
      end
    end

    controller 'feedback' do
      scope '/feedback' do
        get  '/',       action: 'new',    as: :feedback
        post '/',       action: 'create', as: nil
        get  '/thanks', action: 'thanks', as: :thanks_feedback
      end
    end

    controller 'icons' do
      scope action: 'show', format: true do
        constraints size: /\d{2,3}x\d{2,3}/, type: 'precomposed', format: 'png' do
          get '/apple-touch-icon(-:size)(-:type)', as: :apple_touch_icon
        end
      end
    end

    controller 'local_petitions' do
      scope '/petitions/local' do
        get '/',        action: 'index', as: :local_petitions
        get '/:id',     action: 'show',  as: :local_petition
        get '/:id/all', action: 'all',   as: :all_local_petition
      end
    end

    resources :petitions, only: %i[new show index] do
      collection do
        get  'check'
        get  'check_results'
        post 'new', action: 'create', as: nil
        get  'thank-you'
      end

      member do
        get 'count'
        get 'gathering-support'
        get 'moderation-info'
      end

      resources :sponsors, only: %i[new], shallow: true do
        collection do
          post 'new', action: 'create', as: nil
          get  'thank-you'
        end

        member do
          get 'verify'
          get 'sponsored', action: 'signed', as: :signed
        end
      end

      resources :signatures, only: %i[new], shallow: true do
        collection do
          post 'new', action: 'create', as: nil
          get  'thank-you'
        end

        member do
          get 'verify'
          get 'signed'

          match 'unsubscribe', via: %i[get post]
        end
      end
    end

    namespace :archived do
      resources :petitions, only: %i[index show]

      resources :signatures, only: [] do
        match 'unsubscribe', via: %i[get post], on: :member
      end
    end

    # REDIRECTS OLD PAGES
    get '/api/petitions',         to: redirect('/')
    get '/api/petitions/:id',     to: redirect('/')
    get '/crown-copyright',       to: redirect('https://www.nationalarchives.gov.uk/information-management/our-services/crown-copyright.htm')
    get '/departments',           to: redirect('/')
    get '/departments/:id',       to: redirect('/')
    get '/how-it-works',          to: redirect('/help')
    get '/privacy-policy',        to: redirect('/privacy')
    get '/faq',                   to: redirect('/help')
    get '/terms-and-conditions',  to: redirect('/help')

    scope '/images', controller: 'images' do
      get '/:signed_blob_id/:variation_key/*filename', action: 'show', as: :image_proxy
    end
  end

  direct :outcome_image do |image, options|
    signed_blob_id = image.blob.signed_id
    variation_key  = image.variation.key
    filename       = image.blob.filename

    route_for(:image_proxy, signed_blob_id, variation_key, filename, options)
  end

  constraints Site.constraints_for_moderation do
    get '/', to: redirect('/admin')

    namespace :admin do
      mount Delayed::Web::Engine, at: '/delayed'

      root to: 'admin#index'

      resource :parliament, only: %i[show update]
      resource :search, only: %i[show]

      resources :admin_users, only: %[index]
      resources :profile, only: %i[edit update]

      resources :invalidations, except: %i[show] do
        member do
          post :cancel
          post :count
          post :start
        end
      end

      resource :moderation_delay, only: %i[new create], path: 'moderation-delay'

      resources :petitions, only: %i[show index] do
        member do
          post :resend
          post :remove
        end

        resources :emails, controller: 'petition_emails', except: %i[index show]
        resource  :lock, only: %i[show create update destroy]
        resource  :moderation, controller: 'moderation', only: %i[update]
        resource  :statistics, controller: 'petition_statistics', only: %i[update]
        resources :trending_ips, path: 'trending-ips', only: %i[index]
        resources :trending_domains, path: 'trending-domains', only: %i[index]

        scope only: %i[show update] do
          resource :debate_outcome, path: 'debate-outcome'
          resource :notes
          resource :details, controller: 'petition_details'
          resource :schedule_debate, path: 'schedule-debate', controller: 'schedule_debate'
          resource :tags, controller: 'petition_tags'
          resource :take_down, path: 'take-down', controller: 'take_down'
          resource :departments, controller: 'petition_departments'
          resource :topics, controller: 'petition_topics'
          resource :removal, controller: 'petition_removals'
        end

        scope only: %i[show update destroy] do
          resource :government_response, path: 'government-response', controller: 'government_response'
        end

        resources :signatures, only: %i[index destroy] do
          member do
            post :validate
            post :invalidate
            post :subscribe
            post :unsubscribe
          end

          collection do
            delete :destroy, action: :bulk_destroy
            post   :validate, action: :bulk_validate
            post   :invalidate, action: :bulk_invalidate
            post   :subscribe, action: :bulk_subscribe
            post   :unsubscribe, action: :bulk_unsubscribe
          end
        end
      end

      resources :domains, except: %i[show]
      resources :pages, only: %i[index edit update], param: 'slug'
      resources :rejection_reasons, except: %i[show]

      resource :rate_limits, path: 'rate-limits', only: %i[edit update]
      resource :site, only: %i[edit update]
      resource :holidays, only: %i[edit update]
      resource :tasks, only: %i[create]

      resources :signatures, only: %i[index destroy] do
        member do
          post :validate
          post :invalidate
          post :subscribe
          post :unsubscribe
        end

        collection do
          delete :destroy, action: :bulk_destroy
          post   :validate, action: :bulk_validate
          post   :invalidate, action: :bulk_invalidate
          post   :subscribe, action: :bulk_subscribe
          post   :unsubscribe, action: :bulk_unsubscribe
        end

        resource :logs, only: :show
      end

      resources :departments, except: %i[show]
      resources :tags, except: %i[show]
      resources :topics, except: %i[show]

      namespace :archived do
        root to: redirect('/admin/archived/petitions')

        resources :petitions, only: %i[show index] do
          resources :emails, controller: 'petition_emails', except: %i[index show]
          resource  :lock, only: %i[show create update destroy]

          scope only: %i[show update] do
            resource :debate_outcome, path: 'debate-outcome'
            resource :notes
            resource :details, controller: 'petition_details'
            resource :schedule_debate, path: 'schedule-debate', controller: 'schedule_debate'
            resource :tags, controller: 'petition_tags'
            resource :departments, controller: 'petition_departments'
            resource :topics, controller: 'petition_topics'
            resource :removal, controller: 'petition_removals'
          end

          scope only: %i[show update destroy] do
            resource :government_response, path: 'government-response', controller: 'government_response'
          end
        end

        resources :signatures, only: %i[index destroy] do
          member do
            post :subscribe
            post :unsubscribe
          end

          collection do
            delete :destroy, action: :bulk_destroy
            post   :subscribe, action: :bulk_subscribe
            post   :unsubscribe, action: :bulk_unsubscribe
          end
        end
      end

      scope 'stats', controller: 'statistics' do
        get  '/', action: 'index', as: :stats
        post '/', action: 'create', as: nil
      end
    end

    devise_for :users, class_name: 'AdminUser', module: 'admin', skip: %i[sessions]

    as :user do
      controller 'admin/sessions' do
        get  '/admin/login',    action: 'new'
        post '/admin/login',    action: 'create', as: nil
        get  '/admin/logout',   action: 'destroy'
        get  '/admin/continue', action: 'continue'
        get  '/admin/status',   action: 'status'
      end

      controller 'admin/omniauth_callbacks' do
        get '/admin/auth/failure', action: 'failure'

        scope '/admin/auth/:provider', via: %i[get post] do
          match '/',         action: 'passthru', as: :sso_provider
          match '/callback', action: 'saml',     as: :sso_provider_callback
        end
      end
    end
  end

  # Devise needs a `new_user_session_url` helper for its failure app
  direct(:new_user_session) { route_for(:admin_login) }

  get 'ping', to: 'ping#ping'
end
