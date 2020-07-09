package main.java.com.deinersoft.zipster.server;

import main.java.com.deinersoft.zipster.core.Zipster;
import org.json.JSONObject;

import static spark.Spark.*;


public class ZipsterServer {

    public static void main(String[] args) {

        port(8080);
        post("/zipster", (request, response) -> {
            if (request.body().equals("STOP")) stop();
            JSONObject jsonObject = new JSONObject(request.body());

            Zipster zipster = new Zipster(jsonObject.getString("zipcode"), jsonObject.getString("radius"));
            JSONObject resultSet = zipster.getPostOfficesWithinRadius();

            response.type("text/json");
            return resultSet.toString(4);
        });
    }
}