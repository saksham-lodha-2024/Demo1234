package com.campuscircle.models;

public class Category {
    public int    category_id;
    public String category_name;

    public Category() {}
    public Category(int id, String name) { this.category_id = id; this.category_name = name; }

    @Override public String toString() { return category_name; }
}
