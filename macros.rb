module ActiveRecord
  class Base
    def self.has_many(name)
      puts "#{self} has many #{name}"

      define_method(name) do
        puts "SELECT * FROM #{name} WHERE..."
        puts "Returning #{name}"
        []
      end
    end
  end
end

class Movie < ActiveRecord::Base
  has_many :reviews
  has_many :genres
end

class Project < ActiveRecord::Base
  has_many :tasks
end


movie = Movie.new
movie.reviews
movie.reviews
movie.genres

project = Project.new
project.tasks
