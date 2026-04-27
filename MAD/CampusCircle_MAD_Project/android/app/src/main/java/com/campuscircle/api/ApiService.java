package com.campuscircle.api;

import com.campuscircle.models.*;
import retrofit2.Call;
import retrofit2.http.*;
import java.util.List;
import java.util.Map;

/**
 * Retrofit-style contract for the Campus Circle REST API.
 * Every method here maps 1:1 to a backend route.
 */
public interface ApiService {

    // ----- Auth -----
    @POST("api/auth/signup")
    Call<AuthResponse> signup(@Body Map<String, Object> body);

    @POST("api/auth/login")
    Call<AuthResponse> login(@Body Map<String, String> body);

    // ----- Categories -----
    @GET("api/categories")
    Call<List<Category>> getCategories();

    // ----- Items -----
    @GET("api/items")
    Call<List<Item>> getItems(@Query("category") String category);

    @GET("api/items/{id}")
    Call<ItemDetail> getItem(@Path("id") int id);

    @POST("api/items")
    Call<Map<String, Integer>> createItem(@Body Map<String, Object> body);

    @GET("api/items/seller/{user_id}")
    Call<List<Item>> getSellerItems(@Path("user_id") int userId);

    // ----- Transactions -----
    @POST("api/transactions")
    Call<Map<String, Integer>> createTransaction(@Body Map<String, Object> body);

    @GET("api/transactions/buyer/{user_id}")
    Call<List<Transaction>> getBuyerTransactions(@Path("user_id") int userId);

    @GET("api/transactions/seller/{user_id}")
    Call<List<Transaction>> getSellerTransactions(@Path("user_id") int userId);

    @PUT("api/transactions/{id}/status")
    Call<Map<String, Object>> updateTransactionStatus(@Path("id") int id, @Body Map<String, String> body);

    @PUT("api/transactions/{id}/complete")
    Call<Map<String, Object>> completeTransaction(@Path("id") int id);

    @GET("api/transactions/{id}")
    Call<Transaction> getTransaction(@Path("id") int id);

    // ----- Reviews -----
    @POST("api/reviews")
    Call<Map<String, Integer>> submitReview(@Body Map<String, Object> body);

    @GET("api/reviews/user/{id}")
    Call<List<Review>> getReviewsForUser(@Path("id") int id);

    // ----- Users -----
    @GET("api/users/{id}/profile")
    Call<UserProfile> getUserProfile(@Path("id") int id);
}
