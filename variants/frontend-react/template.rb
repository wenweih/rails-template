source_paths.unshift(File.dirname(__FILE__))

TERMINAL.puts_header "Adding react-rails to Gemfile"

gem "react-rails"
run "bundle install"

run "rails generate react:install"

# @testing-library/react brings in @testing-library/dom as a direct dependency,
# and so should be favored when importing as it is the more specific package
run "yarn remove @testing-library/dom"

gsub_file "app/frontend/test/stimulus/controllers/add_class_controller.test.js",
          "'@testing-library/dom'",
          "'@testing-library/react'"

yarn_add_dependencies %w[
  @babel/preset-react
  babel-plugin-transform-react-remove-prop-types
  react
  react-dom
  prop-types
]

yarn_add_dev_dependencies %w[
  @testing-library/react
  eslint-plugin-react
  eslint-plugin-react-hooks
  eslint-plugin-jsx-a11y
]
copy_file ".eslintrc.js", force: true
copy_file "babel.config.js", force: true

# remove example generated by default
remove_file "app/frontend/packs/hello_react.jsx"

react_rails_replacement = <<~REPLACEMENT
  // eslint-disable-next-line react-hooks/rules-of-hooks
  ReactRailsUJS.useContext(componentRequireContext);
REPLACEMENT

gsub_file "app/frontend/packs/application.js",
          "ReactRailsUJS.useContext(componentRequireContext);", react_rails_replacement

gsub_file "app/frontend/packs/server_rendering.js",
          "ReactRailsUJS.useContext(componentRequireContext);", react_rails_replacement

gsub_file(
  "app/frontend/packs/application.js",
  'var ReactRailsUJS = require("react_ujs")',
  ""
)

prepend_to_file "app/frontend/packs/application.js",
                "import ReactRailsUJS from 'react_ujs';\n"

gsub_file(
  "app/frontend/packs/server_rendering.js",
  'var ReactRailsUJS = require("react_ujs")',
  "import ReactRailsUJS from 'react_ujs';"
)

# var ReactRailsUJS = require('react_ujs');
# import ReactRailsUJS from 'react_ujs';

gsub_file "app/views/layouts/application.html.erb",
          "    <%= javascript_pack_tag \"application\", \"data-turbolinks-track\": \"reload\", defer: true %>\n",
          "    <%= javascript_pack_tag \"application\" %>\n"

copy_file "jest.config.js"

# example file
copy_file "app/frontend/components/HelloWorld.jsx", force: true
copy_file "app/frontend/test/components/HelloWorld.spec.jsx", force: true

append_to_file "app/views/home/index.html.erb" do
  <<~ERB
    <%= react_component("HelloWorld", { initialGreeting: "Hello from react-rails." }) %>
  ERB
end

update_package_json do |package_json|
  # we've replaced this with a babel.config.js
  package_json.delete "babel"
end
