require 'pry'
require 'sinatra'
require 'sinatra/reloader'
require 'pg'

def dbname
  "storeadminsite"
end

def with_db
  c = PGconn.new(:host => "localhost", :dbname => dbname, :password => "ilikega")
  yield c
  c.close
end

def get_product_list category
  c = PGconn.new(:host => "localhost", :dbname => "storeadminsite", :password => "ilikega")
  product_list = c.exec_params("SELECT products.name FROM products INNER JOIN prods_cats ON products.id=prods_cats.productID WHERE prods_cats.categoryID=$1;",category)
  c.close
  return product_list
end

get '/' do
  erb :index
end

# The Products machinery:

# Get the index of products
get '/products' do
  c = PGconn.new(:host => "localhost", :dbname => dbname, :password => "ilikega")

  # Get all rows from the products table.
  @products = c.exec_params("SELECT * FROM products;")
  @categories = c.exec_params("SELECT * FROM categories;")
  c.close
  erb :products
end

# Get the form for creating a new product
get '/products/new' do
  c = PGconn.new(:host => "localhost", :dbname => dbname, :password => "ilikega")
  @categories = c.exec_params("SELECT * FROM categories;")
  c.close
  erb :new_product
end

get "/categories" do
  c = PGconn.new(:host => "localhost", :dbname => dbname, :password => "ilikega")
  # @products = c.exec_params("SELECT * FROM products;")
  @categories = c.exec_params("SELECT * FROM categories;")
  # @prods_cats = c.exec_params("SELECT * FROM prods_cats;")

  product_list = get_product_list()

  c.close
  erb :categories
end

get "/categories/new" do
  c = PGconn.new(:host => "localhost", :dbname => dbname, :password => "ilikega")

  c.close
end

# POST to create a new product
post '/products' do
  c = PGconn.new(:host => "localhost", :dbname => dbname, :password => "ilikega")

  # Insert the new row into the products table.
  c.exec_params("INSERT INTO products (name, price, description) VALUES ($1,$2,$3)",
                  [params["name"], params["price"], params["description"]])

  # Assuming you created your products table with "id SERIAL PRIMARY KEY",
  # This will get the id of the product you just created.
  new_product_id = c.exec_params("SELECT currval('products_id_seq');").first["currval"]
  
  # Create the new entry into the prods_cats table
  cat_array = params['categories'].split(",")
  cat_array.each do |cat|
  c.exec_params("INSERT INTO prods_cats (prouctID,categoryID) VALUES ($1,$2);",new_product_id, cat.to_i)
  end
  #close the connection and redirect to new page
  c.close
  redirect "/products/#{new_product_id}"
end

# Update a product
post '/products/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname, :password => "ilikega")

  # Update the product.
  c.exec_params("UPDATE products SET (name, price, description) = ($2, $3, $4) WHERE products.id = $1 ",
                [params["id"], params["name"], params["price"], params["description"]])
  c.close
  redirect "/products/#{params["id"]}"
end

get '/products/:id/edit' do
  c = PGconn.new(:host => "localhost", :dbname => dbname, :password => "ilikega")
  @product = c.exec_params("SELECT * FROM products WHERE products.id = $1", [params["id"]]).first
  c.close
  erb :edit_product
end
# DELETE to delete a product
post '/products/:id/destroy' do

  c = PGconn.new(:host => "localhost", :dbname => dbname, :password => "ilikega")
  c.exec_params("DELETE FROM products WHERE products.id = $1", [params["id"]])
  c.close
  redirect '/products'
end

# GET the show page for a particular product
get '/products/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname, :password => "ilikega")
  @product = c.exec_params("SELECT * FROM products WHERE products.id = $1;", [params[:id]]).first
  c.close
  erb :product
end

def create_products_table
  c = PGconn.new(:host => "localhost", :dbname => dbname, :password => "ilikega")
  c.exec %q{
  CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name varchar(255),
    price decimal,
    description text
  );
  }
  c.close
end

def drop_products_table
  c = PGconn.new(:host => "localhost", :dbname => dbname, :password => "ilikega")
  c.exec "DROP TABLE products;"
  c.close
end

def seed_products_table
  products = [["Laser", "325", "Good for lasering."],                             #4
              ["Shoe", "23.4", "Just the left one."],                             #1,2,3
              ["Wicker Monkey", "78.99", "It has a little wicker monkey baby."],  #8,9
              ["Whiteboard", "125", "Can be written on."],                        #5
              ["Chalkboard", "100", "Can be written on.  Smells like education."],#5
              ["Podium", "70", "All the pieces swivel separately."],              #5
              ["Bike", "150", "Good for biking from place to place."],            #6
              ["Kettle", "39.99", "Good for boiling."],                           #7
              ["Toaster", "20.00", "Toasts your enemies!"],                       #7
             ]

  c = PGconn.new(:host => "localhost", :dbname => dbname, :password => "ilikega")
  products.each do |p|
    c.exec_params("INSERT INTO products (name, price, description) VALUES ($1, $2, $3);", p)
  end
  c.close
end

def create_categories_table
  c = PGconn.new(:host => "localhost", :dbname => dbname, :password => "ilikega")
  c.exec("CREATE TABLE categories(id SERIAL PRIMARY KEY, name TEXT);")
  c.close
end

def seed_categories_table
  categories = [["Footwear"],["Menswear"],["Womenswear"],["Anti-Personnell Weapons"],["Education"],["Transportation"],["Appliances"],["Decoration"],["Doodads"]]
  c = PGconn.new(:host => "localhost", :dbname => dbname, :password => "ilikega")
  categories.each do |cat|
    c.exec_params("INSERT INTO categories (name) VALUES($1);", cat)
  end
  c.close
end

def create_prods_cats_table
  c = PGcon.new(:host => "localhost", :dbname => dbname, :password => "ilikega")
  prods_cats = c.exec("CREATE TABLE prods_cats (id SERIAL PRIMARY KEY, productID INTEGER, categoryID INTEGER")
end

def seed_prods_cats_table
  c = PGcon.new(:host => "localhost", :dbname => dbname, :password => "ilikega")
  c.exec("INSERT INTO prods_cats (productID,categoryID) VALUES (1,4);")
  c.exec("INSERT INTO prods_cats (productID,categoryID) VALUES (2,1);")
  c.exec("INSERT INTO prods_cats (productID,categoryID) VALUES (2,2);")
  c.exec("INSERT INTO prods_cats (productID,categoryID) VALUES (2,3);")
  c.exec("INSERT INTO prods_cats (productID,categoryID) VALUES (3,8);")
  c.exec("INSERT INTO prods_cats (productID,categoryID) VALUES (3,9);")
  c.exec("INSERT INTO prods_cats (productID,categoryID) VALUES (4,5);")
  c.exec("INSERT INTO prods_cats (productID,categoryID) VALUES (5,5);")
  c.exec("INSERT INTO prods_cats (productID,categoryID) VALUES (6,5);")
  c.exec("INSERT INTO prods_cats (productID,categoryID) VALUES (7,6);")
  c.exec("INSERT INTO prods_cats (productID,categoryID) VALUES (8,7);")
  c.exec("INSERT INTO prods_cats (productID,categoryID) VALUES (9,7);")
  c.close
end