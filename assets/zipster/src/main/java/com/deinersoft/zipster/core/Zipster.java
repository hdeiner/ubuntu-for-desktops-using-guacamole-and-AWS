package main.java.com.deinersoft.zipster.core;

import org.apache.commons.io.IOUtils;
import org.json.JSONObject;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.TimeZone;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Zipster {

    private String zipcode;
    private String radius;
    private final String METERS_TO_MILES = "0.000621371192";

    public Zipster(String zipcode, String radius) throws ZipsterException {
        this.zipcode = zipcode;
        this.radius = radius;
    }

    public JSONObject getPostOfficesWithinRadius() {

        JSONObject resultSet = new JSONObject();
        resultSet.put("radius", radius);
        resultSet.put("zipcode", zipcode);

        String dbURL = "jdbc:mysql://mysql_container:3306/zipster?useSSL=false";
        String dbUSER = "root";
        String dbPASSWORD = "password";

        try {
            TimeZone timeZone = TimeZone.getTimeZone("America/New_York");
            TimeZone.setDefault(timeZone);
            Class.forName("com.mysql.cj.jdbc.Driver").newInstance();
            Connection conn = DriverManager.getConnection(dbURL,dbUSER,dbPASSWORD);
            Statement stmt = conn.createStatement();
            ResultSet rs;

            String query =
                    "SELECT T1.*, st_distance_sphere(point(T1.LONGITUDE, T1.LATITUDE), T2.COORDS) * " + METERS_TO_MILES + " AS DISTANCE\n" +
                    "FROM zipster.ZIPCODES AS T1, zipster.ZIPCODES AS T2 \n" +
                    "WHERE st_distance_sphere(point(T1.LONGITUDE, T1.LATITUDE), T2.COORDS) <= " + radius + " / " + METERS_TO_MILES + "\n" +
                    "AND T2.ZIPCODE = " + zipcode + "\n" +
                    "AND T1.ZIPCODE != " + zipcode + "\n" +
                    "ORDER BY st_distance_sphere(point(T1.LONGITUDE, T1.LATITUDE), T2.COORDS) * " + METERS_TO_MILES + " ASC\n";
            System.out.println("query="+query);

            rs = stmt.executeQuery(query);
            while ( rs.next() ) {
                JSONObject row = new JSONObject();
                row.put("zipcode", rs.getString("ZIPCODE"));
                row.put("zipcode_type", rs.getString("ZIPCODE_TYPE"));
                row.put("city", rs.getString("CITY"));
                row.put("state", rs.getString("STATE"));
                row.put("location_type", rs.getString("LOCATION_TYPE"));
                row.put("latitude", rs.getString("LATITUDE"));
                row.put("longitude", rs.getString("LONGITUDE"));
                row.put("location", rs.getString("LOCATION"));
                row.put("decomissioned", rs.getString("DECOMISSIONED"));
                row.put("distance", rs.getString("DISTANCE"));
                System.out.println("row="+row);
                resultSet.append("results", row);
            }
            conn.close();
        } catch (Exception e) {
            resultSet.put("Got an exception!", e.getMessage());
        }

        return resultSet;

    }
}