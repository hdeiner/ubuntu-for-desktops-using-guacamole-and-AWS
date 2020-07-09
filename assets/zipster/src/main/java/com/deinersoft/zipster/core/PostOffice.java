package main.java.com.deinersoft.zipster.core;

public class PostOffice {
    public String zipcode;
    public String zipcode_type;
    public String city;
    public String state;
    public String location_type;
    public String latitude;
    public String longitude;
    public String location;
    public String decomissioned;
    public String distance;

    public PostOffice(String zipcode, String zipcode_type, String city, String state, String location_type, String latitude, String longitude, String location, String decomissioned, String distance) {
        this.zipcode = zipcode;
        this.zipcode_type = zipcode_type;
        this.city = city;
        this.state = state;
        this.location_type = location_type;
        this.latitude = latitude;
        this.longitude = longitude;
        this.location = location;
        this.decomissioned = decomissioned;
        this.distance = distance;
    }
}
