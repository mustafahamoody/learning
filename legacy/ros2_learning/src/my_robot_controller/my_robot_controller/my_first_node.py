#!/bin/python3.12
#   #Interpreter line --> Tells inturpereter where your python 3 inturpreter is to use it

import rclpy #python lib for ros2 -- Must import for every python node in ros2
from rclpy.node import Node  # Base node class for all nodes in ros2

# Creating a node class
class MyNode(Node):
    
    def __init__(self):
        super().__init__("first_node") # Nodes name -- Name that displays in ros2 network tree
        self.counter_ = 0
        self.create_timer(1.0, self.timer_callback)  # Creates a timer that calls a function every x secs

    def timer_callback(self): # function that gets called
        self.get_logger().info("hello from ros2 " + str(self.counter_))
        self.counter_ += 1

def main(args=None):
    rclpy.init(args=args)  # initialise ros2 comunications and rclpy
    node = MyNode()   # creating a node that inherits from MyNode class
    rclpy.spin(node) # the node keeps running and comunicating until stopped --> Allows node callbacks to run
    rclpy.shutdown()  # shutdown ros2 comunications -- Distroy the node and everything inside it, and shuts down ros2 comunications

if __name__ == "__main__":
    main()