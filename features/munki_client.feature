Feature: Munki client API

A munki client uses this application to retrieve software updates.

    Scenario: A client gets its manifest
        Given a client with an identifier of "ff:ff:ff:ff:ff"
        When the client requests its primary manifest
        Then the client be given a valid manifest