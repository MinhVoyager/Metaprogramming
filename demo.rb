# frozen_string_literal: true

# Metaprogramming: Cách mà ruby cho phép code tự tương tác với chính nó, code có thể tự viết ra code khác
# hoặc tự sửa đổi chính mình trong lúc chạy




# 1. Message Passing

# khi gọi 1 method trong ruby, ví dụ: dùng reverse để đảo ngược chuỗi,
# điều
puts 'hello'.reverse

# đây không đơn thuần là gọi hàm như trong các ngôn ngữ khác.
# Ở đây chuỗi 'hello' đang nhận 1 mesage
puts 'hello'.send(:reverse)

arg = :reverse
puts 'hello'.send(arg)

# đây là bản chất của ruby, mọi thứ đều là object
# nên mọi tương tác đều là việc các object gửi message cho nhau

# Với 1 bài toán đơn giản như '2 + 3'
# object '2' đang nhận 1 message là ':+' với đối số là '3'
2.send(:+, 3)




# 2. Ghi đè Hành vi (Overloading Behavior)

# Nhờ cơ chế truyền message đó -> có thể ghi đè hành vi của các toán tử và việc gán thuộc tính.

# a. Ghi đè toán tử (Operator Overloading):

# ví dụ: 2 VND + 5 VND = (2 + 5) VND = 7 VND
# nhưng: 2 VND + 5 USD thì việc cộng không chính xác do 2 đơn vị khác nhau


# có thể xử lý bằng việc tạo 1 class Money

Money.new(2, 'VND') + Money.new(5, 'VND')
Money.new(2, 'VND') + Money.new(5, 'USD') # raise an error

# class Money
class Money
  attr_reader :amount, :currency

  def initialize(amount, currency)
    @amount = amount
    @currency = currency
  end

  def to_s
    "#{@amount} #{@currency}"
  end

  def +(other)
    raise 'Cannot add different currencies' if currency != other.currency

    Money.new(amount + other.amount, currency)
  end
end


object1 = Money.new(2, 'VND')
object2 = Money.new(5, 'VND')

puts object1 + object2



# b. Ghi đè gán thuộc tính (Property Assignment Overloading):

# ví dụ:
require 'ostruct'
objectt = OpenStruct.new

objectt.name = 'minh'
puts objectt

# Việc gán một thuộc tính, ví dụ objectt.name = 'minh', thực chất là một lời gọi method
# với method 'name=' với đối số 'minh'

objectt.send(:name=, 'aaaaa')
puts objectt

# có thể định nghĩa một method kết thúc bằng dấu (=) trong class để can thiệp vào hành vi này

class SomeThing
  def name=(name)
    puts "try to set the name to #{name}"
  end
end

SomeThing.new.name = 'minhhhh'



#---------------------------------------------------------------------------------------------------



# 3. Method missing

# a. Cơ chế

puts 'hello'.how_are_you

# Khi gọi một method trên một đối tượng và method đó không được tìm thấy,
# Ruby sẽ gọi một method đặc biệt có tên là 'method_missing'
# Phương thức 'method_missing' được kế thừa từ 'BasicObject'.
# Việc triển khai 'method_missing' trong 'BasicObject' chỉ đơn giản là tạo ra lỗi 'NoMethodError'

class String < Object
end

class Ojbject < BasicObject
end

class BasicObject
  def method_missing(_method_name, *_arg)
    raise NoMethodError
  end
end

# b. Ghi đè
class SomeMethod
  def method_missing(method_name, *_arg)
    puts "you called: #{method_name}"
  end
end

SomeMethod.new.how_are_you

SomeMethod.new.name = 'minh'

SomeMethod.new + 5

# respond_to_missing
# giữ tính đúng đắng về việc object có thể xử lý method không được khai báo khi dùng .respond_to?()
# logic phải phản ánh chính xác logic của method_missing

class Config
  def initialize
    @config = {}
  end

  def method_missing(method_name, *args)
    name = method_name.to_s
    if name.end_with?('=')
      @config[name.chomp('=').to_sym] = args.first
    else
      @config[name.to_sym]
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    name = method_name.to_s
    (name.end_with?('=') || @config.key?(name.to_sym)) || super
  end
end

config = GoodConfig.new
config.user_name = 'Minh'

puts config.user_name # => "Minh"

puts config.respond_to?(:user_name) # => true
puts config.respond_to?(:user_name=) # => true
puts config.respond_to?(:password) # => false (vì chưa được gán)


#---------------------------------------------------------------------------------------------------


# 4. Define method

# cho phép bạn tạo ra các phương thức một cách tự động, thay vì phải định nghĩa từng cái một

class Car
  def make_blue
    @color = 'blue'
  end

  def make_red
    @color = 'red'
  end

  def make_green
    @color = 'green'
  end
end

class Car
  # Danh sách các màu
  COLORS = %w[blue red green].freeze

  # Dùng vòng lặp để tự động tạo các phương thức
  COLORS.each do |color|
    define_method("make_#{color}") do
      @color = color
      puts "The car is now #{color}"
    end
  end
end

my_car = Car.new
my_car.make_red     # Output: The car is now red
my_car.make_green   # Output: The car is now green


#---------------------------------------------------------------------------------------------------

# 5. Rủi ro

# send:

# a. URL: /posts/1?action=destroy
@post = Post.find(params[:id])

# params[:action] là "destroy" -> @post.destroy
@post.send(params[:action])

# b. Gọi được private method của class

#------------------------------------------------------------

# method_missing:

# Chậm

# mỗi khi một phương thức không tồn tại được gọi,
# ruby phải đi hết chuỗi kế thừa để tìm nó, không thấy, rồi mới gọi method_missing

#------------------------------------------------------------

# define_method:

# khó debug, vì hàm không có trong codebase
