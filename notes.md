# How To Write "Macros" in Ruby

## Intro

- Today in the Studio I'll show you how to define "macros" in Ruby

- Hey folks, Mike Clark here with the Pragmatic Studio.

- Today we're going to tap into the power of Ruby objects and methods to write a class-level declaration, sometimes called a "macro".

- Here's an example of what I'm talking about from Rails...

- The `Movie` model has many reviews and the `Project` model has many tasks:

    ```ruby
    class Movie < ActiveRecord::Base
      has_many :reviews
    end

    class Project < ActiveRecord::Base
      has_many :tasks
    end
    ```

- The first time you encounter a declaration like `has_many`, it looks like something built in to the Ruby language or some magical aspect of Rails

- In fact, it's simply Ruby code. Ruby itself makes programming in this declarative style easier than you might think.
 
- And once you understand how it works, you'll be more confident with Rails and be able to use this same powerful technique in your own Ruby code

- So let's create a simplified version of this code from scratch, building up from the underlying principles that make it work...

## Singleton Methods On An Object

- Open empty `macros.rb` file...

- Here's a simple `String` object:

    ```ruby
    dog1 = "Rosco"

    puts dog1.upcase
    ```

- Ruby lets us define methods on a specific object:

    ```ruby
    def dog1.hunt
      puts "WOOF!"
    end

    dog1.hunt  # => WOOF!
    ```

- Here's a different `String` object:

    ```ruby
    dog2 = "Snoopy"
    ```

- This dog don't hunt:

    ```ruby
    dog2.hunt  # => undefined method `hunt`
    ```

- The `hunt` method is only defined on the `dog1` object

- You'll often hear this referred to as a *singleton method*

- That's interesting, but when would you ever want to do this? 

- Turns out, you use singleton methods all the time in Ruby!

## Classes Are Objects, Too

- Here's a simple `Movie` class:

    ```ruby
    class Movie
    end
    ```

- `Movie` is a constant that references the `Class` object:

    ```ruby
    p Movie.class  # => Class

    p Movie.class.object_id
    ```

- So classes in Ruby are objects, too

- Any given Ruby class is an object of class `Class`

## Singleton Methods On A Class

- If a Ruby class is an object in it's own right, we can treat it like any other object

- Can define singleton method on the `Class` object:

    ```ruby
    movie_class = Movie

    def movie_class.my_class_method
      puts "Running class method..."
    end

    movie_class.my_class_method   # => "Running class method..."
    ```

- `my_class_method` is just a singleton method defined on the `Movie` class object

- Receiver of the call is the `Movie` class object

- Run it!

- Don't need the temporary `movie_class` variable:

    ```ruby
    def Movie.my_class_method
      puts "Running class method..."
    end

    Movie.my_class_method   # => "Running class method..."
    ```

- Run it!

- Or we can move it inside the class declaration:

    ```ruby
    class Movie
      def Movie.my_class_method
        puts "Running class method..."
      end
    end

    Movie.my_class_method
    ```

- Run it!

- Here's the take-away: In Ruby, there is no such thing as a "class method"
- `my_class_method` is just a singleton method defined on the `Movie` class object

- That's the first principle, but it doesn't look like a declaration quite yet

## Classes Are Executable Code

- The second principle is that class definitions are executable code:

    ```ruby
    puts "Before class definition"

    class Movie
      puts "Inside class definition"

      def Movie.my_class_method
        puts "Running class method..."
      end
    end

    puts "After class definition"
    ```

- Run it!

- Code is executed during the process of defining the class

- In that case, we can run the method inside the class:

    ```ruby
    class Movie
      def Movie.my_class_method
        puts "Running class method..."
      end

      Movie.my_class_method
    end
    ```

- But using the `Movie` constant seems repetitive

- Turns out during the class definition, Ruby sets the `self` variable to the class object being defined:

    ```ruby
    puts "Inside class definition of #{self}"
    ```

- Run it!

- Inside the class definition `self` always references the the `Movie` class object

- So we can replace `Movie` with `self`:

    ```ruby
    def self.my_class_method
      puts "Running class method..."
    end

    self.my_class_method
    ```

- Run it!

- If there's no explicit receiver, Ruby uses `self` as the receiver

- If `self` is the implicit receiver, we can remove it:

    ```ruby
    def self.my_class_method
      puts "Running class method..."
    end

    my_class_method
    ```

- Run it!

## Rename

- This is looking closer to a declaration

- Remove the spurious `puts` calls

- Then rename the method so it looks more familiar:

    ```ruby
    class Movie
      def self.has_many(name)
        puts "#{self} has many #{name}"
      end

      has_many :reviews
    end
    ```

- Look familiar?

- Run it to show that it's printed as the class is being defined

- Notice value of `self` is the `Movie` class object

## Define Method

- The `has_many` method is being called during the class definition, so now what should it do?

- In Rails, `has_many` dynamically generates methods for managing the association

- For example, in this case it would generate a `reviews` method that returns the reviews associated with the movie

- We'd call it like so:

    ```ruby
    movie = Movie.new
    movie.reviews   # => undefined method
    ```

- We don't know the name of the method until runtime

- The name of the method is based on the name of the association (`reviews`)

- We need to dynamically generate that method when `has_many` is called

- So here's the method we want to define:

    ```ruby
    def self.has_many(name)
      puts "#{self} has many #{name}"
      def reviews
        puts "SELECT * FROM #{name} WHERE..."
        puts "Returning #{name}..."
        []
      end
    end
    ```

- But hard-coding the method name won't work if we have another relationship:

    ```ruby
    has_many :genres
    ```

- Instead, we have to dynamically define a method for each association

- To do that, we can use `define_method`:

    ```ruby
    def self.has_many(name)
      puts "#{self} has many #{name}"
      define_method(name) do
        puts "SELECT * FROM #{name} WHERE..."
        puts "Returning #{name}..."
        []
      end
    end
    ```

- Body of block is method body

- `define_method` always defines an instance method in the receiver

- Run it to show method is now defined!

- Can call `reviews` multiple times:

    ```ruby
    movie.reviews
    movie.reviews
    ```

- Can now define more `has_many` associations:

    ```ruby
    class Movie < ActiveRecord::Base
      has_many :genres
    end

    movie.genres
    ```

- Cool - now we'd like to share the `has_many` method across classes...

## Class Method Inheritance

- We'll use inheritance to share the `has_many` method:

    ```ruby
    module ActiveRecord
      class Base
        def self.has_many(name)
          puts "#{self} has many #{name}"
          define_method(name) do
            puts "SELECT * FROM #{name}..."
            puts "Returning #{name}..."
          end
        end
      end
    end

    class Movie < ActiveRecord::Base
      has_many :reviews
      has_many :genres
    end
    ```

- Run it to show it still works!

- Notice that value of `self` is the `Movie` class

- Now we can define a new subclass:

    ```ruby
    class Project < ActiveRecord::Base
      has_many :tasks
    end

    project = Project.new
    project.tasks
    ```

- Notice that value of `self` is the `Project` class

## Outro

- That wraps up today's session

- I hope that helps demystify these class-level declarations, sometimes called "macros"

- There's nothing special or magical about these methods - they're just regular Ruby methods that generate code.

- Give 'em a try on your own, and feel free to leave a comment below

- See ya next time!
