// 实验辅助：验证 Go 侧 perfEventData 与内核 oom_info 布局一致
package main

import (
	"fmt"
	"unsafe"
)

// 与 core/events/oom.go 中 perfEventData 字段顺序一致
type perfEventData struct {
	TriggerProcessName [16]byte
	VictimProcessName  [16]byte
	TriggerPid         int32
	VictimPid          int32
	TriggerMemcgCSS    uint64
	VictimMemcgCSS     uint64
}

func main() {
	s := unsafe.Sizeof(perfEventData{})
	fmt.Printf("perfEventData size = %d bytes\n", s)
	fmt.Printf("expected (oom_info in bpf/oom.c) = 16+16+4+4+8+8 = 56 bytes\n")
	if s == 56 {
		fmt.Println("RESULT: PASS - layout size matches kernel struct oom_info")
	} else {
		fmt.Printf("RESULT: FAIL - size mismatch\n")
	}
}
