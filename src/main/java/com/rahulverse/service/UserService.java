package com.rahulverse.service;

import com.rahulverse.model.User;

public interface UserService {
    User register(User user);
    User login(String email, String password);
    User findByEmail(String email);
}
