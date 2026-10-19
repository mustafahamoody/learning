#!/bin/python3.12
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist

class DrawCircleNode(Node):
    def __init__(self):
        super().__init__("draw_circle")
        # Create a publisher
        self.cmv_vel_pub_ = self.create_publisher(Twist, "/turtle1/cmd_vel", 10) #publisher(msg_type, topic, queue size (buffer)) --> can get msg_type with cmd: "ros2 topic info topicName"
        self.timer = self.create_timer(0.5, self.send_velocity_command)
        self.get_logger().info("Draw dircle node has been started")

    def send_velocity_command(self):
        # Create a message (with same message type) to send to publisher
        msg = Twist() #Twist has a lot of properties,such as linear.x, anglualr.z, ..., but you only need to fill what you need
        msg.linear.x = 2.0 
        msg.angular.z = 1.0
        # Publish message from publisher
        self.cmv_vel_pub_.publish(msg)

def main(args=None):
    rclpy.init(args=args)
    node = DrawCircleNode()
    rclpy.spin(node)
    rclpy.shutdown()