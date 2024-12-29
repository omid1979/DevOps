import random
import time
import subprocess

# Define the starting and ending coordinates for Azadi Sq and Valiasr Sq
loc_one = (35.711539, 51.406638)  # Latitude, Longitude for Azadi Square
loc_two = (35.71551,51.42524)  # Latitude, Longitude for Valiasr Square

# Speed in meters per second
speed = 20  # Speed in m/s

# Calculate the distance between the two points using Haversine formula
def haversine(coord1, coord2):
    from math import radians, sin, cos, sqrt, atan2
    
    R = 6371000  # Earth radius in meters
    lat1, lon1 = radians(coord1[0]), radians(coord1[1])
    lat2, lon2 = radians(coord2[0]), radians(coord2[1])
    
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    
    a = sin(dlat / 2)**2 + cos(lat1) * cos(lat2) * sin(dlon / 2)**2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    
    return R * c

# Generate random GPS data along the route
def generate_random_gps_data(start, end, speed):
    total_distance = haversine(start, end)
    duration = total_distance / speed  # Total time to travel in seconds
    
    num_points = int(duration)  # Number of points to generate based on time
    latitudes = []
    longitudes = []
    
    for i in range(num_points + 1):
        # Interpolate between start and end coordinates
        fraction = i / num_points
        lat = start[0] + (end[0] - start[0]) * fraction + random.uniform(-0.0001, 0.0001)
        lon = start[1] + (end[1] - start[1]) * fraction + random.uniform(-0.0001, 0.0001)
        
        latitudes.append(lat)
        longitudes.append(lon)
        
        # Print the generated GPS data point
        print(f"Latitude: {lat:.6f}, Longitude: {lon:.6f}")
        url = f"http://home.omid-online.com:8082/?id=1000020&lat={lat:.6f}&lon={lon:.6f}&altitude=4&speed=20"
        command = ['curl', url]
        
        result = subprocess.run(command, capture_output=True, text=True)
        if result.returncode == 0:
            print("Success:")
            print(result.stdout)  # Print the output from the curl command
        else:
            print("Error:")
            print(result.stderr)  # Print any error messages
        
        time.sleep(1)  # Simulate real-time data sending

# Run the function to generate GPS data
generate_random_gps_data(loc_one, loc_two, speed)

