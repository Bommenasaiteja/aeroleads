# Sample data for development
puts "Creating sample phone numbers and blog posts..."

# Create sample phone numbers (safe test numbers)
test_numbers = [
  { number: "+15005550006", name: "Twilio Test Number 1" },
  { number: "18001234567", name: "Test Toll Free 1" },
  { number: "18002345678", name: "Test Toll Free 2" },
  { number: "18003456789", name: "Test Toll Free 3" },
  { number: "+15005550001", name: "Twilio Test Number 2" }
]

test_numbers.each do |number_data|
  unless PhoneNumber.exists?(number: number_data[:number])
    PhoneNumber.create!(
      number: number_data[:number],
      name: number_data[:name],
      status: 'pending',
      uploaded_at: Time.current
    )
    puts "Created phone number: #{number_data[:number]}"
  end
end

# Create sample blog posts
sample_posts = [
  {
    title: "Getting Started with Ruby on Rails",
    content: "Ruby on Rails is a powerful web framework that follows the MVC pattern. In this post, we'll explore the basics of setting up a Rails application and understanding its core concepts.\n\n## What is Rails?\n\nRails is a web application framework written in Ruby that makes it easy to build database-backed web applications. It follows the convention over configuration principle, which means it makes assumptions about what you want to do and how you're going to do it.\n\n## Key Features\n\n- MVC Architecture\n- Active Record ORM\n- RESTful routing\n- Built-in testing framework\n- Asset pipeline\n\n## Getting Started\n\nTo create a new Rails application:\n\n```bash\nrails new my_app\ncd my_app\nrails server\n```\n\nThis creates a new Rails application with all the necessary files and starts the development server.\n\n## Conclusion\n\nRails provides an excellent foundation for building web applications quickly and efficiently. Its conventions and built-in features allow developers to focus on business logic rather than boilerplate code.",
    author: "Demo Author"
  },
  {
    title: "JavaScript ES6 Features You Should Know",
    content: "ECMAScript 6 (ES6) introduced many new features that make JavaScript more powerful and easier to work with. Let's explore some of the most important ones.\n\n## Arrow Functions\n\nArrow functions provide a more concise way to write function expressions:\n\n```javascript\n// ES5\nvar add = function(a, b) {\n  return a + b;\n};\n\n// ES6\nconst add = (a, b) => a + b;\n```\n\n## Template Literals\n\nTemplate literals allow for easier string interpolation:\n\n```javascript\nconst name = 'John';\nconst greeting = `Hello, ${name}!`;\n```\n\n## Destructuring\n\nDestructuring allows you to extract values from arrays and objects:\n\n```javascript\nconst [first, second] = ['apple', 'banana'];\nconst {name, age} = person;\n```\n\n## Classes\n\nES6 introduced class syntax for creating objects:\n\n```javascript\nclass Person {\n  constructor(name) {\n    this.name = name;\n  }\n  \n  greet() {\n    return `Hello, I'm ${this.name}`;\n  }\n}\n```\n\n## Conclusion\n\nThese ES6 features make JavaScript code more readable, maintainable, and powerful. Adopting them in your projects will improve your development experience.",
    author: "Demo Author"
  }
]

sample_posts.each do |post_data|
  unless BlogPost.exists?(title: post_data[:title])
    BlogPost.create!(
      title: post_data[:title],
      content: post_data[:content],
      author: post_data[:author],
      published_at: Time.current
    )
    puts "Created blog post: #{post_data[:title]}"
  end
end

puts "Sample data created successfully!"
puts "Phone Numbers: #{PhoneNumber.count}"
puts "Blog Posts: #{BlogPost.count}"
