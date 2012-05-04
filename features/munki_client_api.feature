Feature: Munki client API

A munki client uses this application to retrieve software updates.
    
    Background:
        Given a munki client

    Scenario: Primary manifest
        When the client requests its primary manifest
        Then the client is given a valid manifest