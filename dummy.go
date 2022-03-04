package main

import (
	"fmt"
	"log"
	"net"
	"os"

	"github.com/aws/aws-sdk-go/service/autoscaling"
	"github.com/aws/aws-sdk-go/service/ecs"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
)

func main() {
	logger := log.New(os.Stdout, "[dummy-server] ", log.LstdFlags)

	go tcpServer(logger)
	udpServer(logger)
}

func udpServer(logger *log.Logger) {
	host := "0.0.0.0"
	port := 2457 // Steam connection port
	blockSize := 1024

	ip := net.ParseIP(host)
	listener, err := net.ListenUDP("udp", &net.UDPAddr{IP: ip, Port: port})
	if err != nil {
		fmt.Println(err)
		return
	}
	defer listener.Close()

	logger.Printf("listening on addr=%s with block size=%d", listener.LocalAddr(), blockSize)

	data := make([]byte, blockSize)
	for {
		// UDP Listener
		_, remoteAddr, err := listener.ReadFrom(data)
		if err != nil {
			logger.Fatalf("error during read: %s", err)
		}

		logger.Printf("Connection request from <%s>", remoteAddr)
		enableRealServer()
		os.Exit(0)
	}
}

func tcpServer(logger *log.Logger) {
	host := "0.0.0.0"
	healthPort := 8080 // Healthcheck port

	ip := net.ParseIP(host)

	health, err := net.ListenTCP("tcp", &net.TCPAddr{IP: ip, Port: healthPort})
	if err != nil {
		fmt.Println(err)
		return
	}
	defer health.Close()
	logger.Printf("health check listening on addr=%s", health.Addr())

	for {
		// TCP Listener
		conn, err := health.Accept()
		if err != nil {
			panic(err)
		}
		logger.Printf("Received health check request")
		go func(conn net.Conn) {
			conn.Write([]byte("Health check good."))
			conn.Close()
		}(conn)
	}
}

func enableRealServer() {
	valheimService := os.Getenv("VALHEIM_SERVICE")
	dummyService := os.Getenv("DUMMY_SERVICE")
	cluster := os.Getenv("ECS_CLUSTER")
	valheimAsg := os.Getenv("VALHEIM_ASG")

	changeAsgCount(valheimAsg, 1)
	changeServiceCount(cluster, valheimService, 1)
	changeServiceCount(cluster, dummyService, 0)
}

func changeServiceCount(cluster string, service string, count int) {
	svc := ecs.New(session.New())
	input := &ecs.UpdateServiceInput{
			DesiredCount: aws.Int64(int64(count)),
			Service:      aws.String(service),
			Cluster:			aws.String(cluster),
	}

	result, err := svc.UpdateService(input)
	if err != nil {
			if aerr, ok := err.(awserr.Error); ok {
					switch aerr.Code() {
					case ecs.ErrCodeServerException:
							fmt.Println(ecs.ErrCodeServerException, aerr.Error())
					case ecs.ErrCodeClientException:
							fmt.Println(ecs.ErrCodeClientException, aerr.Error())
					case ecs.ErrCodeInvalidParameterException:
							fmt.Println(ecs.ErrCodeInvalidParameterException, aerr.Error())
					case ecs.ErrCodeClusterNotFoundException:
							fmt.Println(ecs.ErrCodeClusterNotFoundException, aerr.Error())
					case ecs.ErrCodeServiceNotFoundException:
							fmt.Println(ecs.ErrCodeServiceNotFoundException, aerr.Error())
					case ecs.ErrCodeServiceNotActiveException:
							fmt.Println(ecs.ErrCodeServiceNotActiveException, aerr.Error())
					case ecs.ErrCodePlatformUnknownException:
							fmt.Println(ecs.ErrCodePlatformUnknownException, aerr.Error())
					case ecs.ErrCodePlatformTaskDefinitionIncompatibilityException:
							fmt.Println(ecs.ErrCodePlatformTaskDefinitionIncompatibilityException, aerr.Error())
					case ecs.ErrCodeAccessDeniedException:
							fmt.Println(ecs.ErrCodeAccessDeniedException, aerr.Error())
					default:
							fmt.Println(aerr.Error())
					}
			} else {
					// Print the error, cast err to awserr.Error to get the Code and
					// Message from an error.
					fmt.Println(err.Error())
			}
			return
	}

	fmt.Println(result)
}

func changeAsgCount(asg string, count int) {
	svc := autoscaling.New(session.New())
	input := &autoscaling.UpdateAutoScalingGroupInput{
			AutoScalingGroupName: aws.String(asg),
			DesiredCapacity:      aws.Int64(int64(count)),
	}
	
	result, err := svc.UpdateAutoScalingGroup(input)
	if err != nil {
			if aerr, ok := err.(awserr.Error); ok {
					switch aerr.Code() {
					case autoscaling.ErrCodeScalingActivityInProgressFault:
							fmt.Println(autoscaling.ErrCodeScalingActivityInProgressFault, aerr.Error())
					case autoscaling.ErrCodeResourceContentionFault:
							fmt.Println(autoscaling.ErrCodeResourceContentionFault, aerr.Error())
					case autoscaling.ErrCodeServiceLinkedRoleFailure:
							fmt.Println(autoscaling.ErrCodeServiceLinkedRoleFailure, aerr.Error())
					default:
							fmt.Println(aerr.Error())
					}
			} else {
					// Print the error, cast err to awserr.Error to get the Code and
					// Message from an error.
					fmt.Println(err.Error())
			}
			return
	}
	
	fmt.Println(result)
}
