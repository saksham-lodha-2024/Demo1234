package com.campuscircle.models;

public class UserProfile {
    public int     user_id;
    public String  name;
    public String  email;
    public String  hostel_block;
    public int     is_verified;
    public String  created_at;

    public Double  avg_rating;
    public Integer review_count;
    public Double  total_earnings;

    public Dashboard dashboard;

    public static class Dashboard {
        public Integer seller_id;
        public String  seller_name;
        public Integer total_listings;
        public Integer active_listings;
        public Integer items_sold;
        public Integer items_rented;
        public Integer completed_transactions;
    }
}
