package com.rahulverse.service;

import com.rahulverse.model.User;
import com.rahulverse.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    public UserServiceImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public User register(User user) {
        // Avoid duplicate emails
        if (userRepository.findByEmail(user.getEmail()).isPresent()) {
            return null;
        }
        return userRepository.save(user);
    }

    @Override
    public User login(String email, String password) {
        Optional<User> user = userRepository.findByEmail(email);
        // NOTE: Plain-text password for demo; use BCrypt in real apps.
        return (user.isPresent() && user.get().getPassword().equals(password)) ? user.get() : null;
    }

    @Override
    public User findByEmail(String email) {
        return userRepository.findByEmail(email).orElse(null);
    }
}
