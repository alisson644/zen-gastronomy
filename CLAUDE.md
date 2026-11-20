# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Zen Gastronomy is a Rails 8 financial-management app for restaurants (Brazilian market — UI text, enum values and domain names are in Portuguese). Stack: PostgreSQL, Devise auth, Hotwire (Turbo + Stimulus), Tailwind v4, esbuild via jsbundling-rails, Propshaft, Solid Cache/Queue/Cable, Kamal for deploy.

## Commands

```bash
bin/setup                      # install deps, prepare DB
bin/dev                        # foreman: rails server + esbuild watch + tailwind watch (Procfile.dev)
bin/rails db:migrate           # schema lives in db/schema.rb

bin/rspec                                          # full test suite (RSpec, not Minitest); never plain `rspec` (gem version clash)
bundle exec rspec spec/models/movement_spec.rb     # single file
bundle exec rspec spec/models/movement_spec.rb:42  # single example by line

bin/rubocop                    # lint (rubocop-rails-omakase; CI runs this)
bin/brakeman --no-pager        # security scan (CI runs this)

yarn build / yarn build:css    # one-off JS / CSS builds into app/assets/builds
bin/rails stimulus:manifest:update  # regenerate app/javascript/controllers/index.js after adding a controller
```

CI (`.github/workflows/ci.yml`) runs only brakeman and rubocop — tests are not run in CI, so run `rspec` locally.

Tests use FactoryBot (`spec/factories`), shoulda-matchers, and transactional fixtures.

## Architecture

### Multi-tenancy by Company
Everything is scoped to a `Company`. A `User` `belongs_to :company` (optional in the schema, but sign-up always creates one: `Users::RegistrationsController#create` runs a two-step form — account (with optional photo) → company — and saves the company and its owner in one transaction; the steps are the `registration-steps` Stimulus controller). A user without a company (only legacy rows) is sent to the profile page. Controllers resolve the tenant via `current_company` (helper in `ApplicationController`; for a system admin it is the company chosen in `session[:viewing_company_id]`) and build records through company associations (`@company.movements.new(...)`); child IDs from params (subcategory, category) are looked up through the company to prevent cross-tenant references. `Movement` also validates that its accounts belong to the same company. Keep this pattern for any new resource.

`ApplicationController` runs `authenticate_user!` for every non-Devise controller (`HomeController` skips it for the public landing page).

### Roles and permissions
- `Permission::ALL` (`app/models/permission.rb`) is the fixed catalog of permission keys. `Permission::COMPANY` is the subset a company can grant; `Permission::GLOBAL` (`companies.view_all`) belongs only to the system admin.
- Roles are per company: `Role belongs_to :company`. Every new company gets the default roles `dono` and `administrativo` (`Role.create_defaults_for!`, called from `Company after_create`). Companies edit those and create their own roles at `/roles`, which requires the `roles.manage` permission.
- `dono` is locked: it always has every `Permission::COMPANY` key, even ones added later. Default roles cannot be deleted.
- The only global role is "Administrador do sistema" (`Role.admin!`, `company_id: nil`). It never appears in a company's roles or team forms.
- A `User` has no role until it has a company: sign-up (`Users::RegistrationsController`) makes the creator the `dono`. A user's role must belong to the user's own company; the global admin role is the only exception.
- Check access with `current_user.can?("key")` in views, and with `requires_permission "key"` (plus `before_action :require_company!` when the page needs a tenant) in controllers. A denied GET redirects with an alert; any other verb returns 403.
- To add a new permission: add it to `Permission::ALL` and check it in code. New roles need no code.
- Promote a system admin with `bin/rails users:make_admin EMAIL=...`.
- In request specs, call `sign_in user.reload` after changing that user's role. Devise's test `sign_in` reuses the in-memory object, so it would otherwise see the old role.

### Company bootstrap
`Company#create_settings_initial` (`after_create_commit`) seeds the default chart of accounts: 12 categories (one income category, "Entrada de caixa", with `is_income: true`), ~70 subcategories, and a "Caixa Dinheiro" cash account. Tests that create a company get all of these rows.

### Movements and balances
`Movement` (`mv_type` enum: `entrada` / `saida` / `transfer`) is the core ledger record. `amount` is always positive; the sign comes from `mv_type`. `Account#current_balance` is a denormalized running balance maintained by Movement callbacks (`after_create` / `after_update` / `after_destroy`) that apply/revert deltas with row locks. A transfer debits `account_id` and credits `related_account_id`. Never update `current_balance` directly when changing movements — go through the model so callbacks keep balances consistent. On account creation, `current_balance` is initialized from `initial_balance` in `AccountsController`.

`Movement#status` is `pago` (default) or `pendente` (accounts payable, e.g. a boleto from a stock entry; only `saida` can be pending). Balance callbacks only apply paid movements; `Movement#pay!` (`PATCH /movements/:id/pay`) flips it and debits the account. `DashboardSummary` only counts paid movements.

`category_id` on a movement is derived server-side from the chosen subcategory (`MovementsController#create`); the form only submits `subcategory_id`.

Note: `adjust_company_cash_if_cash_account!` checks `account_type == "cash"`, but the enum value is `caixa` and `companies` has no `current_balance` column — this branch is effectively dead code.

### Stock (estoque)
- `Supplier`, `Product` (`has_many :suppliers, through: :product_suppliers`; nested `product_suppliers_attributes` with `last_price`), all company-scoped.
- `Product#quantity` / `#average_cost` are denormalized and maintained only by `StockMovement` (`kind`: `entrada` / `saida` / `ajuste`, signed `quantity`, `after_create` with a row lock). Never update them directly. A product with stock history can't be destroyed — deactivate it.
- `StockEntryRegistration` (PORO) saves a `StockEntry` + items in one transaction: one `StockMovement` per item, upserts `ProductSupplier#last_price`, and creates the expense `Movement` (paid on `received_on`, or `pendente` on `due_on` for boleto).
- `StockCount.start!` snapshots active products; `#finalize!` creates `ajuste` movements so stock matches the counted quantities (uncounted items untouched). One open count per company.
- Permissions: `stock.view`, `stock.entries` (entries + manual outputs), `stock.count`, `products.manage`, `suppliers.manage` (`Permission::STOCK` drives the sidebar item; `stock_home_path` picks the first page the user can open).
- Request specs: after a 404 response, call `sign_in` again before the next request (the session cookie isn't rewritten).

### Brazilian number input
`BrazilianDecimal` concern (`brazilian_decimal :amount`) overrides attribute setters so `"1.234,56"` parses as `1234.56`. Paired with the `currency-input` Stimulus controller on the frontend. Use it for any new money attribute.

### Dashboard
`DashboardSummary` (plain Ruby object in `app/models`) aggregates a company's movements for a given month (`?month=YYYY-MM`) — KPIs, month-over-month change, ranked expenses/income (tail collapsed into "Outros"), and a monthly series for charts. Transfers are excluded from income/expense. Rendered by `home/index` with `money-chart` Stimulus controller (Chart.js via `@stimulus-components/chartjs`).

### Turbo-driven modal forms
The financial page (`/financial/index`) creates accounts, categories, subcategories and movements through `<dialog>` modals (`app/views/partials/_modal_create_*.html.erb` + `_*_form.html.erb`). Pattern:
- On success, controllers respond with `create.turbo_stream.erb`, which typically renders `financial/_streams.turbo_stream.erb` to replace the summary, forms and tables by DOM id (`financial_summary`, `account_form`, `transaction_form`, `movements_table`, …).
- On validation failure, they `turbo_stream.replace` the form partial with status `:unprocessable_content`; the `modal-form` Stimulus controller only closes the dialog when `event.detail.success` is true.

When adding a new modal form, follow the same DOM-id + stream-replace contract.

### Assets
JS is bundled by esbuild from `app/javascript/*` into `app/assets/builds`. Stimulus controllers must be registered in `app/javascript/controllers/index.js` (no auto-loading with esbuild). There are two Tailwind entry points (`app/assets/stylesheets/application.tailwind.css` via `yarn build:css`, and `app/assets/tailwind/application.css` via `tailwindcss-rails`), both watched by `Procfile.dev` (outputs `app/assets/builds/application.css` and `app/assets/builds/tailwind.css`). The layout loads all stylesheets via `stylesheet_link_tag :app`.
