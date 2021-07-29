import cv2
import numpy as np

img = cv2.imread('lambo.png')

classes = []

while True:

    cv2.imshow('Image', img)
    cv2.waitKey(1)
