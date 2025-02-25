#!/bin/python3.12
import rclpy
from rclpy.node import Node
from turtlesim.msg import Pose
from geometry_msgs.msg import Twist
from turtlesim.srv import SetPen
from functools import partial

class TurtleControllerNode(Node):
    
    def __init__(self):
        self.previous_x_ = 0
        super().__init__('turtle_controller')

        # Create Publiser
        self.cmd_vel_publisher_ = self.create_publisher(
            Twist, '/turtle1/cmd_vel', 10)

        # Create Subscriber
        self.pose_subscriber_ = self.create_subscription(
            Pose, '/turtle1/pose', self.pose_callback, 10)
    

        self.get_logger().info("Turtle controller has been started.")

    def pose_callback(self, pose: Pose):
        cmd = Twist()
        ## Test Command to check closed loop
        # cmd.linear.x = 5.0
        # cmd.angular.z = 0.0
        
        # If turle is close to wall turn -- values determined emperically
        if pose.x > 9.0 or pose.x < 2.0 or pose.y > 9.0 or pose.y < 2.0:
            cmd.linear.x = 1.0
            cmd.angular.z = 0.9
        # else go straight
        else:
            cmd.linear.x = 5.0
            cmd.angular.z = 0.0

        self.cmd_vel_publisher_.publish(cmd)

        # Change Turtle Trail Colour with service depending on which side of screen it is
        if pose.x > 5.5 and self.previous_x_ <= 5.5: #extra condition to reduce service call rate (speeds up program)
            self.previous_x_ = pose.x
            self.get_logger().info("Set Color to Red!")
            self.call_set_pen_service(255, 0, 0, 3, 0)
        elif pose.x <= 5.5 and self.previous_x_ > 5.5:
            self.previous_x_ = pose.x
            self.get_logger().info("Set Color to Green!")
            self.call_set_pen_service(0, 255, 0, 3, 0)

    def call_set_pen_service(self, r, g, b, width, off):
        # Create Service Client
        client = self.create_client(SetPen, '/turtle1/set_pen')
        # wait for service --> Get error if call not running service
        while not client.wait_for_service(1.0):
            self.get_logger().warn("Waiting for Service...")

        # Client Requests
        request = SetPen.Request()
        request.r = r
        request.b = b
        request.g = g
        request.width = width
        request.off = off

        # Call Service asyncronously --> returns immediatly. If not async, the program will wait until service replies
        future = client.call_async(request) # Gives a future object -- Can work on object, and callback when service responds  
        future.add_done_callback(partial(self.callback_set_pen))


    def callback_set_pen(self, future):
        # Display any exceptions
        try:
            response = future.result()
        except Exception as e:
            self.get_logger().error("Service Call Failed: %r", (e,))



        

def main(args=None):
    rclpy.init(args=args)
    node = TurtleControllerNode()
    rclpy.spin(node)
    rclpy.shutdown()